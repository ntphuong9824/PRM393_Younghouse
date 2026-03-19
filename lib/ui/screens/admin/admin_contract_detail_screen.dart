import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/contract_model.dart';
import '../../../services/contract_service.dart';

class AdminContractDetailScreen extends StatefulWidget {
  final ContractModel contract;
  final String landlordId;

  const AdminContractDetailScreen({
    super.key,
    required this.contract,
    required this.landlordId,
  });

  @override
  State<AdminContractDetailScreen> createState() =>
      _AdminContractDetailScreenState();
}

class _AdminContractDetailScreenState
    extends State<AdminContractDetailScreen> {
  final _db = FirebaseFirestore.instance;
  final _service = ContractService();

  String? _roomLabel;
  String? _tenantName;
  List<String> _coTenantNames = [];
  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final c = widget.contract;
    final results = await Future.wait([
      _resolveRoomLabel(c.roomId),
      _resolveName(c.tenantId),
      ...c.coTenants.map(_resolveName),
    ]);
    if (!mounted) return;
    setState(() {
      _roomLabel = results[0];
      _tenantName = results[1];
      _coTenantNames =
          results.length > 2 ? results.sublist(2) : [];
      _loadingMeta = false;
    });
  }

  Future<String> _resolveRoomLabel(String roomId) async {
    try {
      final roomDoc = await _db.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return roomId;
      final d = roomDoc.data()!;
      final roomNumber = (d['room_number'] as String?) ?? roomId;
      final propertyId = (d['property_id'] as String?) ?? '';
      if (propertyId.isNotEmpty) {
        final propDoc =
            await _db.collection('properties').doc(propertyId).get();
        final propName = (propDoc.data()?['name'] as String?) ?? '';
        if (propName.isNotEmpty) return '$propName - Phòng $roomNumber';
      }
      return 'Phòng $roomNumber';
    } catch (_) {
      return roomId;
    }
  }

  Future<String> _resolveName(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final name =
          (doc.data()?['full_name'] as String?)?.trim() ?? '';
      return name.isNotEmpty ? name : userId;
    } catch (_) {
      return userId;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
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

  String _statusLabel(String s) {
    switch (s) {
      case 'active':
        return 'Đang hiệu lực';
      case 'terminated':
        return 'Đã chấm dứt';
      case 'expired':
        return 'Hết hạn';
      default:
        return s;
    }
  }

  final _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  Future<void> _confirmTerminate() async {
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
              child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Vui lòng nhập lý do')));
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
    if (confirmed != true || !mounted) {
      reasonCtrl.dispose();
      return;
    }
    try {
      await _service.terminateContractTransactional(
        contractId: widget.contract.id,
        landlordId: widget.landlordId,
        terminationReason: reasonCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chấm dứt hợp đồng thành công')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    } finally {
      reasonCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết hợp đồng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              _statusColor(c.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: _statusColor(c.status)),
                        ),
                        child: Text(
                          _statusLabel(c.status),
                          style: TextStyle(
                            color: _statusColor(c.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Thông tin phòng & người thuê
                    _section('Thông tin hợp đồng', [
                      _row(Icons.meeting_room_outlined, 'Phòng',
                          _roomLabel ?? '...'),
                      _row(Icons.person_outline, 'Người thuê',
                          _tenantName ?? '...'),
                      if (_coTenantNames.isNotEmpty)
                        _row(Icons.people_outline, 'Ở cùng',
                            _coTenantNames.join(', ')),
                      _row(Icons.calendar_today_outlined, 'Bắt đầu',
                          DateFormatter.format(c.startDate)),
                      _row(Icons.event_outlined, 'Kết thúc',
                          DateFormatter.format(c.endDate)),
                      if (c.signedAt != null)
                        _row(Icons.draw_outlined, 'Ngày ký',
                            DateFormatter.format(c.signedAt!)),
                    ]),
                    const SizedBox(height: 16),

                    // Tài chính
                    _section('Tài chính', [
                      _row(Icons.attach_money, 'Tiền thuê/tháng',
                          _currency.format(c.monthlyRent)),
                      _row(Icons.savings_outlined, 'Tiền cọc',
                          _currency.format(c.deposit)),
                    ]),
                    const SizedBox(height: 16),

                    // Điều khoản
                    if (c.terms != null && c.terms!.trim().isNotEmpty) ...[
                      _sectionTitle('Điều khoản hợp đồng'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(c.terms!,
                            style: const TextStyle(
                                fontSize: 13, height: 1.6)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Lý do chấm dứt
                    if (c.terminationReason != null &&
                        c.terminationReason!.trim().isNotEmpty) ...[
                      _section('Thông tin chấm dứt', [
                        if (c.terminatedAt != null)
                          _row(Icons.event_busy_outlined, 'Ngày chấm dứt',
                              DateFormatter.format(c.terminatedAt!)),
                        _row(Icons.info_outline, 'Lý do',
                            c.terminationReason!),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 8),

                    // Action button
                    if (c.status == 'active')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _confirmTerminate,
                          icon: const Icon(Icons.cancel,
                              color: Colors.red),
                          label: const Text('CHẤM DỨT HỢP ĐỒNG',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ]),
            ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
      );

  Widget _section(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: rows),
          ),
        ],
      );

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('$label: ',
              style:
                  const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark)),
          ),
        ]),
      );
}
