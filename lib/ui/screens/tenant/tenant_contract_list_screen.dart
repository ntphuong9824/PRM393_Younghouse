import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/contract_model.dart';
import '../../../services/contract_service.dart';
import 'package:yh/ui/screens/tenant/tenant_contract_detail_screen.dart';

class TenantContractListScreen extends StatelessWidget {
  final String userId;

  const TenantContractListScreen({
    super.key,
    required this.userId,
  });

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
        return 'Dang hieu luc';
      case 'terminated':
        return 'Da cham dut';
      case 'expired':
        return 'Het han';
      default:
        return status;
    }
  }

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    return '$dd/$mm/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final service = ContractService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Hop dong cua toi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ContractModel>>(
        stream: service.streamContractsForTenant(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Khong tai duoc danh sach hop dong: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final contracts = snapshot.data ?? const <ContractModel>[];
          if (contracts.isEmpty) {
            return const Center(
              child: Text('Ban chua co hop dong nao'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contracts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final contract = contracts[index];
              final statusColor = _statusColor(contract.status);
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TenantContractDetailScreen(
                      userId: userId,
                      contractId: contract.id,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hop dong: ${contract.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(contract.status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Phong: ${contract.roomId}'),
                      Text('Tu ngay: ${_formatDate(contract.startDate)}'),
                      Text('Den ngay: ${_formatDate(contract.endDate)}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



