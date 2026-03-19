import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/invoice_model.dart';
import '../../../services/invoice_service.dart';

class TenantInvoiceListScreen extends StatefulWidget {
  final String tenantId;
  const TenantInvoiceListScreen({super.key, required this.tenantId});

  @override
  State<TenantInvoiceListScreen> createState() =>
      _TenantInvoiceListScreenState();
}

class _TenantInvoiceListScreenState extends State<TenantInvoiceListScreen>
    with SingleTickerProviderStateMixin {
  final _service = InvoiceService();
  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  late TabController _tabController;
  List<InvoiceModel> _all = [];
  Map<String, String> _roomNumbers = {}; // roomId -> room_number
  bool _isLoading = true;

  int? _filterYear;
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final invoices = await _service.getInvoicesByTenant(widget.tenantId);

    // Resolve room numbers
    final roomIds = invoices.map((i) => i.roomId).toSet();
    final roomNumbers = <String, String>{};
    for (final id in roomIds) {
      if (id.isEmpty) continue;
      final doc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(id)
          .get();
      roomNumbers[id] =
          (doc.data()?['room_number'] as String? ?? id).trim();
    }

    final years = invoices.map((i) => i.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      _all = invoices;
      _roomNumbers = roomNumbers;
      _availableYears = years;
      _filterYear = years.isNotEmpty ? years.first : null;
      _isLoading = false;
    });
  }

  List<InvoiceModel> get _filtered {
    if (_filterYear == null) return _all;
    return _all.where((i) => i.year == _filterYear).toList();
  }

  List<InvoiceModel> get _unpaid =>
      _filtered.where((i) => i.status == 'unpaid' || i.status == 'overdue').toList();
  List<InvoiceModel> get _paid =>
      _filtered.where((i) => i.status == 'paid').toList();

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Đã trả';
      case 'overdue':
        return 'Quá hạn';
      default:
        return 'Chưa trả';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hoá đơn của tôi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Tất cả (${_filtered.length})'),
            Tab(text: 'Chưa trả (${_unpaid.length})'),
            Tab(text: 'Đã trả (${_paid.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryBanner(),
                _buildYearFilter(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_filtered),
                      _buildList(_unpaid),
                      _buildList(_paid),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBanner() {
    final totalDebt = _unpaid.fold(0.0, (s, i) => s + i.totalAmount);
    if (totalDebt == 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.red,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Còn ${_unpaid.length} hoá đơn chưa thanh toán: ${_fmt.format(totalDebt)}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    if (_availableYears.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Năm:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _yearChip(null, 'Tất cả'),
                  ..._availableYears.map((y) => _yearChip(y, '$y')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearChip(int? year, String label) {
    final selected = _filterYear == year;
    return GestureDetector(
      onTap: () => setState(() => _filterYear = year),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<InvoiceModel> invoices) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Không có hoá đơn nào',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (_, i) => _invoiceCard(invoices[i]),
      ),
    );
  }

  Widget _invoiceCard(InvoiceModel inv) {
    final color = _statusColor(inv.status);
    final roomNumber = _roomNumbers[inv.roomId] ?? inv.roomId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _load(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('T${inv.month}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('${inv.year}',
                        style: TextStyle(color: color, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phòng $roomNumber',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark)),
                    const SizedBox(height: 3),
                    Text(_fmt.format(inv.totalAmount),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 3),
                    Text(
                      'Hạn: ${DateFormat('dd/MM/yyyy').format(inv.dueDate)}',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_statusLabel(inv.status),
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
