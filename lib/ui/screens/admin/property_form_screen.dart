import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/property_model.dart';
import '../../../providers/property_provider.dart';

class PropertyFormScreen extends StatefulWidget {
  final String landlordId;
  final PropertyModel? property; // null = thêm mới

  const PropertyFormScreen({super.key, required this.landlordId, this.property});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.property?.name);
  late final _addressCtrl = TextEditingController(text: widget.property?.address);
  late final _wardCtrl = TextEditingController(text: widget.property?.ward);
  late final _districtCtrl = TextEditingController(text: widget.property?.district);
  late final _cityCtrl = TextEditingController(text: widget.property?.city);
  late final _descCtrl = TextEditingController(text: widget.property?.description);
  String _status = 'active';
  bool _isSaving = false;

  bool get _isEdit => widget.property != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _status = widget.property!.status;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _wardCtrl.dispose();
    _districtCtrl.dispose(); _cityCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final provider = context.read<PropertyProvider>();
      if (_isEdit) {
        final updated = PropertyModel(
          id: widget.property!.id,
          landlordId: widget.landlordId,
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          ward: _wardCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          status: _status,
          totalRooms: widget.property!.totalRooms,
          images: widget.property!.images,
          createdAt: widget.property!.createdAt,
          updatedAt: DateTime.now(),
        );
        await provider.updateProperty(updated);
      } else {
        await provider.addProperty(
          landlordId: widget.landlordId,
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          ward: _wardCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          description: _descCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa tòa nhà' : 'Thêm tòa nhà',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _field(_nameCtrl, 'Tên tòa nhà', Icons.apartment),
            const SizedBox(height: 16),
            _field(_addressCtrl, 'Số nhà, tên đường', Icons.location_on),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _field(_wardCtrl, 'Phường/Xã', Icons.map)),
              const SizedBox(width: 12),
              Expanded(child: _field(_districtCtrl, 'Quận/Huyện', Icons.map, required: false)),
            ]),
            const SizedBox(height: 16),
            _field(_cityCtrl, 'Tỉnh/Thành phố', Icons.location_city),
            const SizedBox(height: 16),
            _field(_descCtrl, 'Mô tả', Icons.description, required: false, maxLines: 3),
            const SizedBox(height: 16),
            if (_isEdit) ...[
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: const Icon(Icons.toggle_on, color: AppColors.primary),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                  DropdownMenuItem(value: 'inactive', child: Text('Tạm đóng')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEdit ? 'CẬP NHẬT' : 'THÊM TÒA NHÀ',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool required = true, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: required ? (v) => v == null || v.isEmpty ? 'Vui lòng nhập $label' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
