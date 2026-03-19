import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRoomOption {
  final String id;
  final String roomNumber;
  final String propertyName;
  final double basePrice;
  final double depositAmount;

  const AdminRoomOption({
    required this.id,
    required this.roomNumber,
    required this.propertyName,
    required this.basePrice,
    required this.depositAmount,
  });

  String get displayLabel => '$propertyName - Phong $roomNumber';
}

class AdminTenantOption {
  final String id;
  final String fullName;
  final String phone;
  final String email;

  const AdminTenantOption({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
  });

  String get displayLabel {
    if (fullName.isNotEmpty) return fullName;
    if (phone.isNotEmpty) return phone;
    if (email.isNotEmpty) return email;
    return id;
  }
}

class ContractService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamContractsByLandlord(
    String landlordId,
  ) {
    return _db
        .collection('contracts')
        .where('landlord_id', isEqualTo: landlordId)
        .snapshots();
  }

  Future<List<AdminRoomOption>> getVacantRoomsByLandlord(String landlordId) async {
    final propertySnap = await _db
        .collection('properties')
        .where('landlord_id', isEqualTo: landlordId)
        .get();

    if (propertySnap.docs.isEmpty) {
      return const [];
    }

    final propertyNameById = <String, String>{
      for (final d in propertySnap.docs)
        d.id: ((d.data()['name'] as String?) ?? '').trim(),
    };
    final propertyIds = propertyNameById.keys.toList();

    final rooms = <AdminRoomOption>[];
    for (var i = 0; i < propertyIds.length; i += 10) {
      final chunk = propertyIds.skip(i).take(10).toList();
      final roomSnap = await _db
          .collection('rooms')
          .where('property_id', whereIn: chunk)
          .where('status', isEqualTo: 'vacant')
          .get();

      for (final doc in roomSnap.docs) {
        final data = doc.data();
        rooms.add(
          AdminRoomOption(
            id: doc.id,
            roomNumber: ((data['room_number'] as String?) ?? '').trim(),
            propertyName: propertyNameById[data['property_id']] ?? 'Toa nha',
            basePrice: (data['base_price'] ?? 0).toDouble(),
            depositAmount: (data['deposit_amount'] ?? 0).toDouble(),
          ),
        );
      }
    }

    rooms.sort((a, b) {
      final byProperty = a.propertyName.compareTo(b.propertyName);
      if (byProperty != 0) return byProperty;
      return a.roomNumber.compareTo(b.roomNumber);
    });

    return rooms;
  }

  Future<List<AdminTenantOption>> getTenantsByLandlord(String landlordId) async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'tenant')
        .where('landlord_id', isEqualTo: landlordId)
        .get();

    final tenants = snap.docs
        .map(
          (d) => AdminTenantOption(
            id: d.id,
            fullName: ((d.data()['full_name'] as String?) ?? '').trim(),
            phone: ((d.data()['phone'] as String?) ?? '').trim(),
            email: ((d.data()['email'] as String?) ?? '').trim(),
          ),
        )
        .toList();

    tenants.sort((a, b) => a.displayLabel.compareTo(b.displayLabel));
    return tenants;
  }

  Future<String> createContractTransactional({
    required String landlordId,
    required String roomId,
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required String terms,
    required List<String> coTenants,
    String? pdfUrl,
  }) async {
    final contractRef = _db.collection('contracts').doc();
    final roomRef = _db.collection('rooms').doc(roomId);
    final tenantRef = _db.collection('users').doc(tenantId);

    await _db.runTransaction((txn) async {
      final roomSnap = await txn.get(roomRef);
      if (!roomSnap.exists) {
        throw Exception('Phong khong ton tai');
      }

      final room = roomSnap.data() as Map<String, dynamic>;
      final roomStatus = (room['status'] as String?) ?? 'vacant';
      if (roomStatus != 'vacant') {
        throw Exception('Phong da co nguoi thue hoac khong san sang');
      }

      final tenantSnap = await txn.get(tenantRef);
      if (!tenantSnap.exists) {
        throw Exception('Nguoi thue khong ton tai');
      }
      final tenant = tenantSnap.data() as Map<String, dynamic>;
      final tenantRole = (tenant['role'] as String?) ?? '';
      if (tenantRole != 'tenant') {
        throw Exception('Tai khoan duoc chon khong phai tenant');
      }
      final tenantLandlordId = (tenant['landlord_id'] as String?) ?? '';
      if (tenantLandlordId != landlordId) {
        throw Exception('Tenant khong thuoc admin hien tai');
      }

      final contractData = <String, dynamic>{
        'room_id': roomId,
        'tenant_id': tenantId,
        'landlord_id': landlordId,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'monthly_rent': (room['base_price'] ?? 0).toDouble(),
        'deposit': (room['deposit_amount'] ?? 0).toDouble(),
        'co_tenants': coTenants,
        'terms': terms.trim(),
        'status': 'active',
        'pdf_url': (pdfUrl ?? '').trim().isEmpty ? null : pdfUrl!.trim(),
        'signed_at': null,
        'terminated_at': null,
        'termination_reason': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      txn.set(contractRef, contractData);
      txn.update(roomRef, {
        'current_tenant_id': tenantId,
        'current_contract_id': contractRef.id,
        'status': 'occupied',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    return contractRef.id;
  }

  Future<void> terminateContractTransactional({
    required String contractId,
    required String landlordId,
    required String terminationReason,
  }) async {
    final contractRef = _db.collection('contracts').doc(contractId);

    await _db.runTransaction((txn) async {
      final contractSnap = await txn.get(contractRef);
      if (!contractSnap.exists) {
        throw Exception('Hop dong khong ton tai');
      }

      final contract = contractSnap.data() as Map<String, dynamic>;
      final owner = (contract['landlord_id'] as String?) ?? '';
      if (owner != landlordId) {
        throw Exception('Ban khong co quyen chinh sua hop dong nay');
      }

      final status = (contract['status'] as String?) ?? '';
      if (status != 'active') {
        throw Exception('Chi co the cham dut hop dong dang active');
      }

      final roomId = (contract['room_id'] as String?) ?? '';
      if (roomId.isEmpty) {
        throw Exception('Hop dong khong co room_id hop le');
      }
      final roomRef = _db.collection('rooms').doc(roomId);
      final roomSnap = await txn.get(roomRef);

      txn.update(contractRef, {
        'status': 'terminated',
        'terminated_at': FieldValue.serverTimestamp(),
        'termination_reason': terminationReason.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (roomSnap.exists) {
        final room = roomSnap.data() as Map<String, dynamic>;
        final currentContractId = (room['current_contract_id'] as String?) ?? '';
        if (currentContractId == contractId) {
          txn.update(roomRef, {
            'current_contract_id': null,
            'current_tenant_id': null,
            'status': 'vacant',
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }
}

