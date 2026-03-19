import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/invoice_model.dart';
import '../../../services/invoice_service.dart';
import 'admin_create_invoice_screen.dart';
import 'admin_invoice_detail_screen.dart';

class AdminInvoiceListScreen extends StatefulWidget {
  final String landlordId;
  const AdminInvoiceListScreen({super.key, required this.landlordId});

  @override
  State<AdminInvoiceListScreen> createState() => _AdminInvoiceListScreenState();
}

class _AdminInvoiceListScreenState extends State<AdminInvoiceListScreen>
    with SingleTickerProviderStateMixin {
  final _service = InvoiceService();
  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  late TabController _tabController;
  List<InvoiceModel> _all = [];
  bool _isLoading = true;

  int? _filterYear;
  int? _filterMonth;
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
    final invoices = await _service.getInvoicesByLandlord(widget.landlordId);
    final years = invoices.map((i) => i.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    setState(() {
      _all = invoices;
      _availableYears = years;
      _filterYear ??= years.isNotEmpty ? years.first : null;
      _isLoading = false;
    });
  }

  List<InvoiceModel> get _filtered {
    return _all.where((i) {
      if (_filterYear != null && i.year != _filterYear) return false;
      if (_filterMonth != null && i.month != _filterMonth) return false;
      return true;
    }).toList();
  }

  List<InvoiceModel> get _unpaid =>
      _filtered.where((i) => i.status == 'unpaid' || i.status == 'overdue').toList();
  List<InvoiceModel> get _paid =>
      _filtered.where((i) => i.status == 'paid').toList();

  double get _totalRevenue =>
      _paid.fold(0.0, (s, i) => s + i.totalAmount);
  double get _totalDebt =>
      _unpaid.fold(0.0, (s, i) => s + i.totalAmount);

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
        title: const Text('Quản lý hoá đơn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tạo hoá đơn',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminCreateInvoiceScreen(landlordId: widget.landlordId),
                ),
              );
              _load();
            },
          ),
        ],
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
                _buildStatsBanner(),
                _buildFilters(),
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

  Widget _buildStatsBanner() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: _statBox(
              'Đã thu',
              _fmt.format(_totalRevenue),
              Icons.check_circle_outline,
              Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statBox(
              'Còn nợ',
              _fmt.format(_totalDebt),
              Icons.warning_amber_rounded,
              Colors.yellow.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Year filter
          Row(
            children: [
              const Text('Năm:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(null, 'Tất cả', _filterYear == null,
                          () => setState(() {
                                _filterYear = null;
                                _filterMonth = null;
                              })),
                      ..._availableYears.map((y) => _chip(
                            y,
                            '$y',
                            _filterYear == y,
                            () => setState(() {
                              _filterYear = y;
                              _filterMonth = null;
                            }),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_filterYear != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Tháng:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(null, 'Tất cả', _filterMonth == null,
                            () => setState(() => _filterMonth = null)),
                        ...List.generate(
                          12,
                          (i) => _chip(
                            i + 1,
                            'T${i + 1}',
                            _filterMonth == i + 1,
                            () => setState(() => _filterMonth = i + 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(dynamic value, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 12,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminInvoiceDetailScreen(
                invoice: inv,
                landlordId: widget.landlordId,
              ),
            ),
          );
          _load();
        },
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
                    Text('Phòng ${inv.roomId}',
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
