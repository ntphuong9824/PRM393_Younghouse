import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/contract_model.dart';
import '../../../services/contract_service.dart';

class _ContractDisplay {
  final ContractModel contract;
  final String roomNumber;
  final String propertyName;
  final Map<String, String> userNames; // userId -> full_name

  const _ContractDisplay({
    required this.contract,
    required this.roomNumber,
    required this.propertyName,
    required this.userNames,
  });
}

class TenantContractDetailScreen extends StatelessWidget {
  final String userId;
  final String contractId;

  const TenantContractDetailScreen({
    super.key,
    required this.userId,
    required this.contractId,
  });

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    return '$dd/$mm/${value.year}';
  }

  String _money(double value) {
    final formatted = value
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '$formatted đ';
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

  Future<_ContractDisplay> _load() async {
    final db = FirebaseFirestore.instance;
    final service = ContractService();

    final contract = await service.getContractDetailForTenant(
      contractId: contractId,
      userId: userId,
    );
    if (contract == null) throw Exception('Hợp đồng không tồn tại');

    // Fetch room info
    String roomNumber = contract.roomId;
    String propertyName = '';
    final roomDoc = await db.collection('rooms').doc(contract.roomId).get();
    if (roomDoc.exists) {
      final rd = roomDoc.data()!;
      roomNumber = (rd['room_number'] as String? ?? contract.roomId).trim();
      final propertyId = (rd['property_id'] as String? ?? '').trim();
      if (propertyId.isNotEmpty) {
        final propDoc =
            await db.collection('properties').doc(propertyId).get();
        propertyName =
            (propDoc.data()?['name'] as String? ?? '').trim();
      }
    }

    // Fetch user names for tenant + co-tenants
    final allIds = {contract.tenantId, ...contract.coTenants}
        .where((id) => id.isNotEmpty)
        .toList();
    final userNames = <String, String>{};
    for (final id in allIds) {
      final doc = await db.collection('users').doc(id).get();
      final name =
          (doc.data()?['full_name'] as String? ?? '').trim();
      userNames[id] = name.isNotEmpty ? name : id;
    }

    return _ContractDisplay(
      contract: contract,
      roomNumber: roomNumber,
      propertyName: propertyName,
      userNames: userNames,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết hợp đồng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<_ContractDisplay>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể xem hợp đồng: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final display = snapshot.data!;
          final contract = display.contract;
          final isPrimary = contract.tenantId == userId;
          final roomLabel = display.propertyName.isNotEmpty
              ? 'Phòng ${display.roomNumber} - ${display.propertyName}'
              : 'Phòng ${display.roomNumber}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(
                title: 'Thông tin chung',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line('Phòng', roomLabel),
                    _line('Ngày bắt đầu', _formatDate(contract.startDate)),
                    _line('Ngày kết thúc', _formatDate(contract.endDate)),
                    _line('Tiền thuê tháng', _money(contract.monthlyRent)),
                    _line('Tiền cọc', _money(contract.deposit)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(contract.status)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(contract.status),
                        style: TextStyle(
                          color: _statusColor(contract.status),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _section(
                title: 'Người trong hợp đồng',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(
                      'Người thuê chính',
                      '${display.userNames[contract.tenantId] ?? contract.tenantId}'
                          '${isPrimary ? ' (bạn)' : ''}',
                    ),
                    if (contract.coTenants.isEmpty)
                      _line('Người ở cùng', 'Không có')
                    else
                      ...contract.coTenants.map(
                        (id) => _line(
                          'Người ở cùng',
                          '${display.userNames[id] ?? id}'
                              '${id == userId ? ' (bạn)' : ''}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _section(
                title: 'Điều khoản',
                child: Text(
                  (contract.terms ?? '').trim().isEmpty
                      ? 'Không có điều khoản'
                      : contract.terms!.trim(),
                  style: const TextStyle(color: AppColors.textDark),
                ),
              ),
              if ((contract.pdfUrl ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _section(
                  title: 'File hợp đồng',
                  child: SelectableText(contract.pdfUrl!.trim()),
                ),
              ],
              if ((contract.terminationReason ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _section(
                  title: 'Lý do chấm dứt',
                  child: Text(contract.terminationReason!.trim()),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textDark, fontSize: 14),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
