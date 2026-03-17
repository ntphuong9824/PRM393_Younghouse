import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String tenantId;
  const CreateInvoiceScreen({super.key, required this.tenantId});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = InvoiceService();
  bool _isLoading = false;

  final _roomIdCtrl = TextEditingController(text: 'R302');
  final _rentCtrl = TextEditingController(text: '1800000');
  final _electricPriceCtrl = TextEditingController(text: '3000');
  final _electricPrevCtrl = TextEditingController();
  final _electricCurrCtrl = TextEditingController();
  final _waterPriceCtrl = TextEditingController(text: '15000');
  final _waterPrevCtrl = TextEditingController(text: '0');
  final _waterCurrCtrl = TextEditingController(text: '0');
  final _otherFeesCtrl = TextEditingController(text: '0');

  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  double get _electricUsed => ((int.tryParse(_electricCurrCtrl.text) ?? 0) -
          (int.tryParse(_electricPrevCtrl.text) ?? 0))
      .clamp(0, 99999)
      .toDouble();
  double get _electricCost =>
      _electricUsed * (double.tryParse(_electricPriceCtrl.text) ?? 0);
  double get _waterUsed => ((int.tryParse(_waterCurrCtrl.text) ?? 0) -
          (int.tryParse(_waterPrevCtrl.text) ?? 0))
      .clamp(0, 99999)
      .toDouble();
  double get _waterCost =>
      _waterUsed * (double.tryParse(_waterPriceCtrl.text) ?? 0);
  double get _total =>
      (double.tryParse(_rentCtrl.text) ?? 0) +
      _electricCost +
      _waterCost +
      (double.tryParse(_otherFeesCtrl.text) ?? 0);

  Future<void> _pickMonth() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn tháng'),
        content: SizedBox(
          width: 280,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, childAspectRatio: 1.2),
            itemCount: 12,
            itemBuilder: (_, i) {
              final m = i + 1;
              final sel = m == _month;
              return GestureDetector(
                onTap: () {
                  setState(() => _month = m);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('T$m',
                        style: TextStyle(
                            color: sel ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.bold)),
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
    final ePrev = int.tryParse(_electricPrevCtrl.text) ?? 0;
    final eCurr = int.tryParse(_electricCurrCtrl.text) ?? 0;
    if (eCurr < ePrev) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ số điện cuối phải >= chỉ số đầu')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final invoice = InvoiceModel(
        id: const Uuid().v4(),
        contractId: '',
        roomId: _roomIdCtrl.text.trim(),
        tenantId: widget.tenantId,
        landlordId: '',
        month: _month,
        year: _year,
        electricPrev: ePrev,
        electricCurr: eCurr,
        electricPrice: double.tryParse(_electricPriceCtrl.text) ?? 0,
        waterPrev: int.tryParse(_waterPrevCtrl.text) ?? 0,
        waterCurr: int.tryParse(_waterCurrCtrl.text) ?? 0,
        waterPrice: double.tryParse(_waterPriceCtrl.text) ?? 0,
        rentAmount: double.tryParse(_rentCtrl.text) ?? 0,
        otherFees: double.tryParse(_otherFeesCtrl.text) ?? 0,
        totalAmount: _total,
        status: 'unpaid',
        dueDate: DateTime(_year, _month + 1, 10),
        createdBy: widget.tenantId,
        createdAt: now,
        updatedAt: now,
      );
      await _service.createInvoice(invoice);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _roomIdCtrl.dispose();
    _rentCtrl.dispose();
    _electricPriceCtrl.dispose();
    _electricPrevCtrl.dispose();
    _electricCurrCtrl.dispose();
    _waterPriceCtrl.dispose();
    _waterPrevCtrl.dispose();
    _waterCurrCtrl.dispose();
    _otherFeesCtrl.dispose();
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
              // Tháng
              _label('Tháng lập hoá đơn'),
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
                  child: Row(children: [
                    const Icon(Icons.calendar_month, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text('Tháng $_month/$_year',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Thông tin phòng
              _label('Thông tin phòng'),
              const SizedBox(height: 8),
              _card([
                _field(_roomIdCtrl, 'Mã phòng', Icons.meeting_room),
                const SizedBox(height: 12),
                _numField(_rentCtrl, 'Tiền phòng (₫)', Icons.attach_money),
              ]),
              const SizedBox(height: 20),

              // Điện
              _label('Chỉ số điện'),
              const SizedBox(height: 8),
              _card([
                _numField(_electricPriceCtrl, 'Giá điện/số (₫)', Icons.bolt),
                const SizedBox(height: 12),
                _numField(
                    _electricPrevCtrl, 'Chỉ số đầu kỳ', Icons.electric_meter),
                const SizedBox(height: 12),
                _numField(
                    _electricCurrCtrl, 'Chỉ số cuối kỳ', Icons.electric_meter),
                if (_electricUsed > 0) ...[
                  const SizedBox(height: 8),
                  Text('Tiêu thụ: ${_electricUsed.toInt()} số',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ]),
              const SizedBox(height: 20),

              // Nước
              _label('Chỉ số nước'),
              const SizedBox(height: 8),
              _card([
                _numField(_waterPriceCtrl, 'Giá nước/m³ (₫)', Icons.water_drop),
                const SizedBox(height: 12),
                _numField(_waterPrevCtrl, 'Chỉ số đầu kỳ', Icons.water),
                const SizedBox(height: 12),
                _numField(_waterCurrCtrl, 'Chỉ số cuối kỳ', Icons.water),
              ]),
              const SizedBox(height: 20),

              // Phí khác
              _label('Phí khác'),
              const SizedBox(height: 8),
              _card([
                _numField(_otherFeesCtrl, 'Phí khác (₫)', Icons.receipt),
              ]),
              const SizedBox(height: 20),

              // Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  _previewRow(
                      'Tiền phòng', double.tryParse(_rentCtrl.text) ?? 0),
                  const SizedBox(height: 6),
                  _previewRow('Tiền điện', _electricCost),
                  const SizedBox(height: 6),
                  _previewRow('Tiền nước', _waterCost),
                  const SizedBox(height: 6),
                  _previewRow(
                      'Phí khác', double.tryParse(_otherFeesCtrl.text) ?? 0),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG CỘNG',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_fmt.format(_total),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary)),
                    ],
                  ),
                ]),
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

  Widget _label(String t) => Text(t,
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

  Widget _numField(TextEditingController c, String label, IconData icon) =>
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
          Text(_fmt.format(amount),
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      );
}
