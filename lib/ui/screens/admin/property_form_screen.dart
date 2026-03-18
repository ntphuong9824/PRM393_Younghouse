import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/property_model.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/app_form_field.dart';
import '../../widgets/app_save_button.dart';

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
        await provider.updateProperty(
          widget.property!.copyWith(
            name: _nameCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            ward: _wardCtrl.text.trim(),
            district: _districtCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            status: _status,
            updatedAt: DateTime.now(),
          ),
        );
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
            AppFormField(controller: _nameCtrl, label: 'Tên tòa nhà', icon: Icons.apartment),
            const SizedBox(height: 16),
            AppFormField(controller: _addressCtrl, label: 'Số nhà, tên đường', icon: Icons.location_on),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: AppFormField(controller: _wardCtrl, label: 'Phường/Xã', icon: Icons.map)),
              const SizedBox(width: 12),
              Expanded(child: AppFormField(controller: _districtCtrl, label: 'Quận/Huyện', icon: Icons.map, required: false)),
            ]),
            const SizedBox(height: 16),
            AppFormField(controller: _cityCtrl, label: 'Tỉnh/Thành phố', icon: Icons.location_city),
            const SizedBox(height: 16),
            AppFormField(controller: _descCtrl, label: 'Mô tả', icon: Icons.description, required: false, maxLines: 3),
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
            AppSaveButton(
              label: _isEdit ? 'CẬP NHẬT' : 'THÊM TÒA NHÀ',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ]),
        ),
      ),
    );
  }
}
