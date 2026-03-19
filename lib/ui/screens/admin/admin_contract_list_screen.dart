import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/contract_model.dart';
import '../../../services/contract_service.dart';
import 'admin_contract_detail_screen.dart';
import 'admin_create_contract_screen.dart';

const _kPageSize = 10;

class AdminContractListScreen extends StatefulWidget {
  final String landlordId;
  const AdminContractListScreen({super.key, required this.landlordId});

  @override
  State<AdminContractListScreen> createState() =>
      _AdminContractListScreenState();
}

class _AdminContractListScreenState extends State<AdminContractListScreen> {
  final _service = ContractService();
  final _db = FirebaseFirestore.instance;

  // Cache tên để tránh gọi Firestore lặp lại
  final _roomCache = <String, String>{};
  final _tenantCache = <String, String>{};

  String _query = '';
  String _filterStatus = 'all';
  int _currentPage = 0;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTime _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final d = _asDate(value);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'terminated':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Đang hiệu lực';
      case 'terminated':
        return 'Đã chấm dứt';
      case 'expired':
        return 'Hết hạn';
      default:
        return status;
    }
  }

  Future<String> _getRoomLabel(String roomId) async {
    if (_roomCache.containsKey(roomId)) return _roomCache[roomId]!;
    try {
      final roomDoc = await _db.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return roomId;
      final roomData = roomDoc.data()!;
      final roomNumber = (roomData['room_number'] as String?) ?? roomId;
      final propertyId = (roomData['property_id'] as String?) ?? '';
      if (propertyId.isNotEmpty) {
        final propDoc =
            await _db.collection('properties').doc(propertyId).get();
        final propName =
            (propDoc.data()?['name'] as String?) ?? '';
        final label =
            propName.isNotEmpty ? '$propName - Phòng $roomNumber' : 'Phòng $roomNumber';
        _roomCache[roomId] = label;
        return label;
      }
      _roomCache[roomId] = 'Phòng $roomNumber';
      return _roomCache[roomId]!;
    } catch (_) {
      return roomId;
    }
  }

  Future<String> _getTenantName(String tenantId) async {
    if (_tenantCache.containsKey(tenantId)) return _tenantCache[tenantId]!;
    try {
      final doc = await _db.collection('users').doc(tenantId).get();
      final name = (doc.data()?['full_name'] as String?)?.trim() ?? '';
      final label = name.isNotEmpty ? name : tenantId;
      _tenantCache[tenantId] = label;
      return label;
    } catch (_) {
      return tenantId;
    }
  }

  Future<void> _confirmDelete(String contractId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá hợp đồng'),
        content: const Text('Bạn có chắc muốn xoá hợp đồng này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteContract(contractId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá hợp đồng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmTerminate(String contractId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chấm dứt hợp đồng'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nhập lý do chấm dứt hợp đồng:'),
          const SizedBox(height: 10),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Ví dụ: Hết nhu cầu thuê phòng',
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng nhập lý do chấm dứt')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Chấm dứt',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonCtrl.dispose();
      return;
    }

    try {
      await _service.terminateContractTransactional(
        contractId: contractId,
        landlordId: widget.landlordId,
        terminationReason: reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chấm dứt hợp đồng thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không chấm dứt được hợp đồng: $e')),
      );
    } finally {
      reasonCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh sách hợp đồng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminCreateContractScreen(landlordId: widget.landlordId),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo hợp đồng'),
      ),
      body: Column(children: [
        // Thanh tìm kiếm + filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() { _query = v.trim().toLowerCase(); _currentPage = 0; }),
              decoration: InputDecoration(
                hintText: 'Tìm theo phòng, người thuê...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() { _query = ''; _currentPage = 0; });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('all', 'Tất cả'),
                const SizedBox(width: 8),
                _filterChip('active', 'Đang hiệu lực'),
                const SizedBox(width: 8),
                _filterChip('expired', 'Hết hạn'),
                const SizedBox(width: 8),
                _filterChip('terminated', 'Đã chấm dứt'),
              ]),
            ),
            const SizedBox(height: 10),
          ]),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                _service.streamContractsByLandlord(widget.landlordId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Không tải được danh sách hợp đồng: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              var docs =
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? const [],
              )..sort((a, b) {
                  final aDate = _asDate(a.data()['created_at']);
                  final bDate = _asDate(b.data()['created_at']);
                  return bDate.compareTo(aDate);
                });

              // Filter theo status
              if (_filterStatus != 'all') {
                docs = docs
                    .where((d) => d.data()['status'] == _filterStatus)
                    .toList();
              }

              // Filter theo query (dùng cache đã có)
              if (_query.isNotEmpty) {
                docs = docs.where((d) {
                  final roomId = d.data()['room_id'] as String? ?? '';
                  final tenantId = d.data()['tenant_id'] as String? ?? '';
                  final roomLabel =
                      (_roomCache[roomId] ?? roomId).toLowerCase();
                  final tenantLabel =
                      (_tenantCache[tenantId] ?? tenantId).toLowerCase();
                  return roomLabel.contains(_query) ||
                      tenantLabel.contains(_query);
                }).toList();
              }

              if (docs.isEmpty) {
                return const Center(
                    child: Text('Không có hợp đồng nào',
                        style: TextStyle(color: Colors.grey)));
              }

              final totalPages = (docs.length / _kPageSize).ceil();
              final page = _currentPage.clamp(0, totalPages - 1);
              final pageItems =
                  docs.skip(page * _kPageSize).take(_kPageSize).toList();

              return Column(children: [
                Expanded(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: pageItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildContractCard(pageItems[index]),
                  ),
                ),
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 90),
                    child: _buildPagination(page, totalPages),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filterStatus = value;
        _currentPage = 0;
      }),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = (data['status'] as String?) ?? 'unknown';
    final roomId = (data['room_id'] as String?) ?? '';
    final tenantId = (data['tenant_id'] as String?) ?? '';

    return FutureBuilder<List<String>>(
      future: Future.wait([
        _getRoomLabel(roomId),
        _getTenantName(tenantId),
      ]),
      builder: (context, snap) {
        final roomLabel = snap.data?[0] ?? roomId;
        final tenantName = snap.data?[1] ?? tenantId;
        final contract = ContractModel.fromFirestore(doc);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminContractDetailScreen(
                contract: contract,
                landlordId: widget.landlordId,
              ),
            ),
          ),
          child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      roomLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.person_outline,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(tenantName,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.date_range,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatDate(data['start_date'])} → ${_formatDate(data['end_date'])}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ]),
                if ((data['termination_reason'] as String?)
                        ?.trim()
                        .isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 4),
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 15, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Lý do: ${data['termination_reason']}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ]),
                ],
                if (status == 'active') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmTerminate(doc.id),
                      icon: const Icon(Icons.cancel,
                          color: Colors.red, size: 16),
                      label: const Text('Chấm dứt',
                          style: TextStyle(
                              color: Colors.red, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
                if (status != 'active') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(doc.id),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.grey, size: 16),
                      label: const Text('Xoá',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ]),
          ),
        );
      },
    );
  }

  Widget _buildPagination(int current, int total) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: current > 0
            ? () => setState(() => _currentPage = current - 1)
            : null,
        color: AppColors.primary,
      ),
      ...List.generate(total, (i) {
        final isActive = i == current;
        return GestureDetector(
          onTap: () => setState(() => _currentPage = i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        );
      }),
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: current < total - 1
            ? () => setState(() => _currentPage = current + 1)
            : null,
        color: AppColors.primary,
      ),
    ]);
  }
}
