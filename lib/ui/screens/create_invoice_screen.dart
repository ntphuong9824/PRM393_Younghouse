import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/invoice_model.dart';
import '../../models/room_model.dart';
import '../../services/invoice_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceService = InvoiceService();
  bool _isLoading = false;

  final _roomIdCtrl = TextEditingController(text: 'R302');
  final _roomNameCtrl = TextEditingController(text: 'Phòng 302');
  final _baseRentCtrl = TextEditingController(text: '1800000');
  final _waterPerPersonCtrl = TextEditingController(text: '100000');
  final _numberOfPeopleCtrl = TextEditingController(text: '2');
  final _electricityPriceCtrl = TextEditingController(text: '3000');
  final _electricityStartCtrl = TextEditingController();
  final _electricityEndCtrl = TextEditingController();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  double get _electricityUsed {
    final start = double.tryParse(_electricityStartCtrl.text) ?? 0;
    final end = double.tryParse(_electricityEndCtrl.text) ?? 0;
    return (end - start).clamp(0, double.infinity);
  }

  double get _electricityCost =>
      _electricityUsed * (double.tryParse(_electricityPriceCtrl.text) ?? 0);

  double get _waterTotal =>
      (double.tryParse(_waterPerPersonCtrl.text) ?? 0) *
      (int.tryParse(_numberOfPeopleCtrl.text) ?? 1);

  double get _totalAmount =>
      (double.tryParse(_baseRentCtrl.text) ?? 0) +
      _waterTotal +
      _electricityCost;

  Future<void> _pickMonth() async {
    int year = _selectedMonth.year;
    int month = _selectedMonth.month;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn tháng'),
        content: SizedBox(
          width: 280,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.2,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final m = i + 1;
              final selected = m == month;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMonth = DateTime(year, m));
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('T$m',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final start = double.tryParse(_electricityStartCtrl.text) ?? 0;
    final end = double.tryParse(_electricityEndCtrl.text) ?? 0;
    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Chỉ số điện cuối phải lớn hơn chỉ số đầu')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final room = RoomModel(
        roomId: _roomIdCtrl.text.trim(),
        roomName: _roomNameCtrl.text.trim(),
        baseRent: double.parse(_baseRentCtrl.text),
        waterServicePerPerson: double.parse(_waterPerPersonCtrl.text),
        numberOfPeople: int.parse(_numberOfPeopleCtrl.text),
        electricityPricePerUnit: double.parse(_electricityPriceCtrl.text),
      );
      final invoiceId =
          'INV-${_roomIdCtrl.text.trim()}-${_selectedMonth.month.toString().padLeft(2, '0')}-${_selectedMonth.year}';
      final invoice = InvoiceModel(
        id: invoiceId,
        room: room,
        month: _selectedMonth,
        electricityStart: start,
        electricityEnd: end,
        isPaid: false,
        createdAt: DateTime.now(),
      );
      await _invoiceService.createInvoice(invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tạo hoá đơn thành công!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _roomIdCtrl.dispose();
    _roomNameCtrl.dispose();
    _baseRentCtrl.dispose();
    _waterPerPersonCtrl.dispose();
    _numberOfPeopleCtrl.dispose();
    _electricityPriceCtrl.dispose();
    _electricityStartCtrl.dispose();
    _electricityEndCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo hoá đơn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Tháng ---
              _sectionLabel('Tháng lập hoá đơn'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickMonth,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // --- Thông tin phòng ---
              _sectionLabel('Thông tin phòng'),
              const SizedBox(height: 8),
              _card([
                _field(_roomIdCtrl, 'Mã phòng', Icons.meeting_room),
                const SizedBox(height: 12),
                _field(_roomNameCtrl, 'Tên phòng', Icons.home),
                const SizedBox(height: 12),
                _numField(_baseRentCtrl, 'Tiền phòng (₫)', Icons.attach_money),
              ]),

              const SizedBox(height: 20),
              // --- Nước & Dịch vụ ---
              _sectionLabel('Nước & Dịch vụ'),
              const SizedBox(height: 8),
              _card([
                _numField(_waterPerPersonCtrl, 'Tiền nước/người (₫)',
                    Icons.water_drop),
                const SizedBox(height: 12),
                _numField(_numberOfPeopleCtrl, 'Số người ở', Icons.people,
                    isInt: true),
              ]),

              const SizedBox(height: 20),
              // --- Chỉ số điện ---
              _sectionLabel('Chỉ số điện'),
              const SizedBox(height: 8),
              _card([
                _numField(_electricityPriceCtrl, 'Giá điện/số (₫)', Icons.bolt),
                const SizedBox(height: 12),
                _numField(_electricityStartCtrl, 'Chỉ số đầu kỳ',
                    Icons.electric_meter),
                const SizedBox(height: 12),
                _numField(_electricityEndCtrl, 'Chỉ số cuối kỳ',
                    Icons.electric_meter),
                if (_electricityUsed > 0) ...[
                  const SizedBox(height: 8),
                  Text('Tiêu thụ: ${_electricityUsed.toInt()} số',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ]),

              const SizedBox(height: 20),
              // --- Preview tổng tiền ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _previewRow(
                        'Tiền phòng', double.tryParse(_baseRentCtrl.text) ?? 0),
                    const SizedBox(height: 6),
                    _previewRow('Nước & Dịch vụ', _waterTotal),
                    const SizedBox(height: 6),
                    _previewRow('Tiền điện', _electricityCost),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TỔNG CỘNG',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          _currencyFormat.format(_totalAmount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('TẠO HOÁ ĐƠN',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark));

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  Widget _field(TextEditingController c, String label, IconData icon) =>
      TextFormField(
        controller: c,
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Vui lòng nhập $label' : null,
        decoration: _deco(label, icon),
      );

  Widget _numField(TextEditingController c, String label, IconData icon,
          {bool isInt = false}) =>
      TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Vui lòng nhập $label';
          if (double.tryParse(v) == null) return 'Giá trị không hợp lệ';
          return null;
        },
        decoration: _deco(label, icon),
      );

  Widget _previewRow(String label, double amount) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Text(_currencyFormat.format(amount),
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      );
}
