import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/contract_model.dart';
import '../../../services/contract_service.dart';

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

  String _money(double value) => value.toStringAsFixed(0);

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

  @override
  Widget build(BuildContext context) {
    final service = ContractService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chi tiết hợp đồng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ContractModel?>(
        future: service.getContractDetailForTenant(
          contractId: contractId,
          userId: userId,
        ),
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

          final contract = snapshot.data;
          if (contract == null) {
            return const Center(
              child: Text('Hợp đồng không tồn tại hoặc bạn không có quyền xem'),
            );
          }

          final isPrimaryTenant = contract.tenantId == userId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(
                title: 'Thông tin chung',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line('Mã hợp đồng', contract.id),
                    _line('Phòng', contract.roomId),
                    _line('Ngày bắt đầu', _formatDate(contract.startDate)),
                    _line('Ngày kết thúc', _formatDate(contract.endDate)),
                    _line('Tiền thuê tháng', _money(contract.monthlyRent)),
                    _line('Tiền cọc', _money(contract.deposit)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                      '${contract.tenantId}${isPrimaryTenant ? ' (bạn)' : ''}',
                    ),
                    if (contract.coTenants.isEmpty)
                      _line('Người ở cùng', 'Không có')
                    else
                      ...contract.coTenants.map(
                        (id) => _line(
                          'Người ở cùng',
                          '$id${id == userId ? ' (bạn)' : ''}',
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}

