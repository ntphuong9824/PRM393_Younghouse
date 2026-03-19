import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/property_model.dart';
import '../../../providers/property_provider.dart';
import '../../../services/vietnam_address_service.dart';
import '../../widgets/app_form_field.dart';
import '../../widgets/app_save_button.dart';

class PropertyFormScreen extends StatefulWidget {
  final String landlordId;
  final PropertyModel? property;

  const PropertyFormScreen({super.key, required this.landlordId, this.property});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressService = VietnamAddressService();

  late final _nameCtrl = TextEditingController(text: widget.property?.name);
  late final _addressCtrl = TextEditingController(text: widget.property?.address);
  late final _descCtrl = TextEditingController(text: widget.property?.description);
  String _status = 'active';
  bool _isSaving = false;

  // Address cascade state
  List<ProvinceModel> _provinces = const [];
  List<DistrictModel> _districts = const [];
  List<WardModel> _wards = const [];

  ProvinceModel? _selectedProvince;
  DistrictModel? _selectedDistrict;
  WardModel? _selectedWard;

  bool _loadingProvinces = true;
  bool _loadingDistricts = false;
  bool _loadingWards = false;

  bool get _isEdit => widget.property != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _status = widget.property!.status;
    _loadProvinces();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await _addressService.getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _loadingProvinces = false;
      });
      // Restore saved values when editing
      if (_isEdit) {
        final savedCity = widget.property!.city.trim();
        final match = _provinces.where(
          (p) => p.name.toLowerCase() == savedCity.toLowerCase(),
        );
        if (match.isNotEmpty) {
          await _onProvinceChanged(match.first, restoring: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProvinces = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được tỉnh/thành: $e')),
      );
    }
  }

  Future<void> _onProvinceChanged(ProvinceModel province,
      {bool restoring = false}) async {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = const [];
      _wards = const [];
      _loadingDistricts = true;
    });
    try {
      final districts = await _addressService.getDistricts(province.code);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
      });
      if (restoring && _isEdit) {
        final savedDistrict = widget.property!.district.trim();
        final match = _districts.where(
          (d) => d.name.toLowerCase() == savedDistrict.toLowerCase(),
        );
        if (match.isNotEmpty) {
          await _onDistrictChanged(match.first, restoring: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _onDistrictChanged(DistrictModel district,
      {bool restoring = false}) async {
    setState(() {
      _selectedDistrict = district;
      _selectedWard = null;
      _wards = const [];
      _loadingWards = true;
    });
    try {
      final wards = await _addressService.getWards(district.provinceCode, district.code);
      if (!mounted) return;
      setState(() {
        _wards = wards;
        _loadingWards = false;
      });
      if (restoring && _isEdit) {
        final savedWard = widget.property!.ward.trim();
        final match = _wards.where(
          (w) => w.name.toLowerCase() == savedWard.toLowerCase(),
        );
        if (match.isNotEmpty) {
          setState(() => _selectedWard = match.first);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingWards = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tỉnh/thành phố')),
      );
      return;
    }
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn quận/huyện')),
      );
      return;
    }
    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phường/xã')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final provider = context.read<PropertyProvider>();
      final city = _selectedProvince!.name;
      final district = _selectedDistrict!.name;
      final ward = _selectedWard!.name;

      if (_isEdit) {
        await provider.updateProperty(
          widget.property!.copyWith(
            name: _nameCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            ward: ward,
            district: district,
            city: city,
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
          ward: ward,
          district: district,
          city: city,
          description: _descCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppFormField(
                  controller: _nameCtrl,
                  label: 'Tên tòa nhà',
                  icon: Icons.apartment),
              const SizedBox(height: 16),
              AppFormField(
                  controller: _addressCtrl,
                  label: 'Số nhà, tên đường',
                  icon: Icons.location_on),
              const SizedBox(height: 16),

              // Tỉnh / Thành phố
              _loadingProvinces
                  ? _loadingField('Đang tải tỉnh/thành phố...')
                  : _AddressDropdown<ProvinceModel>(
                      label: 'Tỉnh/Thành phố',
                      icon: Icons.location_city,
                      value: _selectedProvince,
                      items: _provinces,
                      itemLabel: (p) => p.name,
                      onChanged: (p) => _onProvinceChanged(p),
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn tỉnh/thành phố' : null,
                    ),
              const SizedBox(height: 16),

              // Quận / Huyện
              _loadingDistricts
                  ? _loadingField('Đang tải quận/huyện...')
                  : _AddressDropdown<DistrictModel>(
                      label: 'Quận/Huyện',
                      icon: Icons.map,
                      value: _selectedDistrict,
                      items: _districts,
                      itemLabel: (d) => d.name,
                      enabled: _selectedProvince != null,
                      onChanged: (d) => _onDistrictChanged(d),
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn quận/huyện' : null,
                    ),
              const SizedBox(height: 16),

              // Phường / Xã
              _loadingWards
                  ? _loadingField('Đang tải phường/xã...')
                  : _AddressDropdown<WardModel>(
                      label: 'Phường/Xã',
                      icon: Icons.map_outlined,
                      value: _selectedWard,
                      items: _wards,
                      itemLabel: (w) => w.name,
                      enabled: _selectedDistrict != null,
                      onChanged: (w) => setState(() => _selectedWard = w),
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn phường/xã' : null,
                    ),
              const SizedBox(height: 16),

              AppFormField(
                  controller: _descCtrl,
                  label: 'Mô tả',
                  icon: Icons.description,
                  required: false,
                  maxLines: 3),
              const SizedBox(height: 16),

              if (_isEdit) ...[
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    prefixIcon:
                        const Icon(Icons.toggle_on, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'active', child: Text('Đang hoạt động')),
                    DropdownMenuItem(
                        value: 'inactive', child: Text('Tạm đóng')),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingField(String label) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.hourglass_empty, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const SizedBox(
        height: 20,
        child: LinearProgressIndicator(),
      ),
    );
  }
}

// ── Generic address dropdown ─────────────────────────────────────

class _AddressDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const _AddressDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: Text(enabled ? 'Chọn $label' : 'Chọn cấp trên trước'),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: enabled ? (v) { if (v != null) onChanged(v); } : null,
      validator: validator,
    );
  }
}
