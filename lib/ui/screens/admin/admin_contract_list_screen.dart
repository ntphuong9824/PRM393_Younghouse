import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/contract_service.dart';
import 'admin_create_contract_screen.dart';

class AdminContractListScreen extends StatefulWidget {
  final String landlordId;

  const AdminContractListScreen({
    super.key,
    required this.landlordId,
  });

  @override
  State<AdminContractListScreen> createState() => _AdminContractListScreenState();
}

class _AdminContractListScreenState extends State<AdminContractListScreen> {
  final _service = ContractService();

  DateTime _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final d = _asDate(value);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
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
        return 'Dang hieu luc';
      case 'terminated':
        return 'Da cham dut';
      case 'expired':
        return 'Het han';
      default:
        return status;
    }
  }

  Future<void> _confirmTerminate(String contractId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cham dut hop dong'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhap ly do cham dut hop dong:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Vi du: Het nhu cau thue phong',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huy'),
          ),
          TextButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui long nhap ly do cham dut')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Cham dut', style: TextStyle(color: Colors.red)),
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
        const SnackBar(content: Text('Cham dut hop dong thanh cong')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong cham dut duoc hop dong: $e')),
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
        title: const Text(
          'Danh sach hop dong',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCreateContractScreen(landlordId: widget.landlordId),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tao hop dong'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.streamContractsByLandlord(widget.landlordId),
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

          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.data?.docs ?? const [],
          )
            ..sort((a, b) {
              final aDate = _asDate(a.data()['created_at']);
              final bDate = _asDate(b.data()['created_at']);
              return bDate.compareTo(aDate);
            });

          if (docs.isEmpty) {
            return const Center(child: Text('Chua co hop dong nao'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final status = (data['status'] as String?) ?? 'unknown';
              final roomId = (data['room_id'] as String?) ?? '';
              final tenantId = (data['tenant_id'] as String?) ?? '';

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hop dong: ${doc.id}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12),
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
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Room: $roomId'),
                    Text('Tenant: $tenantId'),
                    Text('Tu ngay: ${_formatDate(data['start_date'])}'),
                    Text('Den ngay: ${_formatDate(data['end_date'])}'),
                    if ((data['termination_reason'] as String?)?.trim().isNotEmpty == true)
                      Text('Ly do cham dut: ${data['termination_reason']}'),
                    const SizedBox(height: 10),
                    if (status == 'active')
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmTerminate(doc.id),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            'Cham dut hop dong',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

