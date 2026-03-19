import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room_model.dart';
import '../../../models/room_service_model.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/app_form_field.dart';
import '../../widgets/app_save_button.dart';

// Dịch vụ mặc định gợi ý
const _kServicePresets = [
  {'name': 'electric', 'label': 'Điện', 'unit': 'kWh', 'metered': true},
  {'name': 'water', 'label': 'Nước', 'unit': 'person', 'metered': false},
  {'name': 'internet', 'label': 'Internet', 'unit': 'person', 'metered': false},
  {'name': 'trash', 'label': 'Rác', 'unit': 'person', 'metered': false},
  {'name': 'parking', 'label': 'Gửi xe', 'unit': 'person', 'metered': false},
];

class _ServiceEntry {
  final String id;
  String serviceName;
  String unit;
  bool isMetered;
  final TextEditingController priceCtrl;

  _ServiceEntry({
    required this.id,
    required this.serviceName,
    required this.unit,
    required this.isMetered,
    double price = 0,
  }) : priceCtrl = TextEditingController(
            text: price > 0 ? price.toStringAsFixed(0) : '');

  void dispose() => priceCtrl.dispose();
}

class RoomFormScreen extends StatefulWidget {
  final String propertyId;
  final RoomModel? room;
  const RoomFormScreen({super.key, required this.propertyId, this.room});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _roomNumberCtrl =
      TextEditingController(text: widget.room?.roomNumber);
  late final _floorCtrl = TextEditingController(
      text: widget.room?.floor.toString() ?? '1');
  late final _areaCtrl = TextEditingController(
      text: widget.room?.areaSqm.toString() ?? '');
  late final _priceCtrl = TextEditingController(
      text: widget.room?.basePrice.toString() ?? '');
  late final _depositCtrl = TextEditingController(
      text: widget.room?.depositAmount.toString() ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.room?.description ?? '');
  String _status = 'vacant';
  List<File> _newImages = [];
  List<String> _existingImages = [];
  bool _isSaving = false;
  bool _loadingServices = false;

  final List<_ServiceEntry> _services = [];

  bool get _isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _status = widget.room!.status;
      _existingImages = List.from(widget.room!.images);
      _loadExistingServices();
    }
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _floorCtrl.dispose();
    _areaCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();
    _descCtrl.dispose();
    for (final s in _services) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingServices() async {
    setState(() => _loadingServices = true);
    try {
      final provider = context.read<PropertyProvider>();
      final list = await provider.getRoomServices(widget.room!.id);
      if (!mounted) return;
      setState(() {
        _services.addAll(list.map((s) => _ServiceEntry(
              id: s.id,
              serviceName: s.serviceName,
              unit: s.unit,
              isMetered: s.isMetered,
              price: s.pricePerUnit,
            )));
      });
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  void _addService(Map<String, dynamic> preset) {
    // Không thêm trùng
    if (_services.any((s) => s.serviceName == preset['name'])) return;
    setState(() {
      _services.add(_ServiceEntry(
        id: const Uuid().v4(),
        serviceName: preset['name'] as String,
        unit: preset['unit'] as String,
        isMetered: preset['metered'] as bool,
      ));
    });
  }

  void _addCustomService() {
    setState(() {
      _services.add(_ServiceEntry(
        id: const Uuid().v4(),
        serviceName: '',
        unit: 'person',
        isMetered: false,
      ));
    });
  }

  void _removeService(int index) {
    final entry = _services[index];
    entry.dispose();
    setState(() => _services.removeAt(index));
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() => _newImages.addAll(picked.map((x) => File(x.path))));
    }
  }

  List<RoomServiceModel> _buildServiceModels(String roomId) {
    final now = DateTime.now();
    return _services.map((s) {
      return RoomServiceModel(
        id: s.id,
        roomId: roomId,
        serviceName: s.serviceName.trim(),
        unit: s.unit,
        pricePerUnit: double.tryParse(s.priceCtrl.text) ?? 0,
        isMetered: s.isMetered,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final provider = context.read<PropertyProvider>();
      if (_isEdit) {
        final services = _buildServiceModels(widget.room!.id);
        await provider.updateRoom(
          widget.room!.copyWith(
            roomNumber: _roomNumberCtrl.text.trim(),
            floor: int.tryParse(_floorCtrl.text) ?? 1,
            areaSqm: double.tryParse(_areaCtrl.text) ?? 0,
            basePrice: double.tryParse(_priceCtrl.text) ?? 0,
            depositAmount: double.tryParse(_depositCtrl.text) ?? 0,
            description: _descCtrl.text.trim(),
            images: _existingImages,
            status: _status,
            updatedAt: DateTime.now(),
          ),
          newImages: _newImages,
          services: services,
        );
      } else {
        await provider.addRoom(
          propertyId: widget.propertyId,
          roomNumber: _roomNumberCtrl.text.trim(),
          floor: int.tryParse(_floorCtrl.text) ?? 1,
          areaSqm: double.tryParse(_areaCtrl.text) ?? 0,
          basePrice: double.tryParse(_priceCtrl.text) ?? 0,
          depositAmount: double.tryParse(_depositCtrl.text) ?? 0,
          description: _descCtrl.text.trim(),
          imageFiles: _newImages,
          services: _buildServiceModels('__placeholder__'),
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

  Widget _buildExistingImage(String imageSource) {
    if (imageSource.startsWith('data:image')) {
      try {
        final commaIndex = imageSource.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(imageSource.substring(commaIndex + 1));
          return Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover);
        }
      } catch (_) {}
      return const SizedBox(
          width: 80, height: 80, child: Icon(Icons.broken_image));
    }
    return Image.network(imageSource,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
            width: 80, height: 80, child: Icon(Icons.broken_image)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa phòng' : 'Thêm phòng',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: AppFormField(
                      controller: _roomNumberCtrl,
                      label: 'Số phòng',
                      icon: Icons.meeting_room)),
              const SizedBox(width: 12),
              Expanded(
                  child: AppFormField(
                      controller: _floorCtrl,
                      label: 'Tầng',
                      icon: Icons.layers,
                      isNumber: true)),
            ]),
            const SizedBox(height: 16),
            AppFormField(
                controller: _areaCtrl,
                label: 'Diện tích (m²)',
                icon: Icons.square_foot,
                isNumber: true,
                required: false),
            const SizedBox(height: 16),
            AppFormField(
                controller: _priceCtrl,
                label: 'Giá thuê (₫)',
                icon: Icons.attach_money,
                isNumber: true),
            const SizedBox(height: 16),
            AppFormField(
                controller: _depositCtrl,
                label: 'Tiền cọc (₫)',
                icon: Icons.savings,
                isNumber: true),
            const SizedBox(height: 16),
            AppFormField(
                controller: _descCtrl,
                label: 'Mô tả / Tiện nghi',
                icon: Icons.description,
                required: false,
                maxLines: 3),
            const SizedBox(height: 16),

            const SizedBox(height: 8),

            // ── Dịch vụ phòng ──────────────────────────────────
            _buildServicesSection(),
            const SizedBox(height: 24),

            // Ảnh phòng
            const Text('Ảnh phòng',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ..._existingImages.map((url) => Stack(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildExistingImage(url)),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _existingImages.remove(url)),
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ])),
              ..._newImages.map((file) => Stack(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(file,
                            width: 80, height: 80, fit: BoxFit.cover)),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _newImages.remove(file)),
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ])),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.add_photo_alternate,
                      color: AppColors.primary),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            AppSaveButton(
              label: _isEdit ? 'CẬP NHẬT PHÒNG' : 'THÊM PHÒNG',
              isLoading: _isSaving,
              onPressed: _save,
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.electrical_services, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        const Text('Dịch vụ phòng',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const Spacer(),
        if (_loadingServices)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
      const SizedBox(height: 12),

      // Nút gợi ý nhanh
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kServicePresets.map((preset) {
          final added = _services.any((s) => s.serviceName == preset['name']);
          return FilterChip(
            label: Text(preset['label'] as String),
            selected: added,
            onSelected: (_) => added
                ? _removeService(
                    _services.indexWhere((s) => s.serviceName == preset['name']))
                : _addService(preset),
            selectedColor: AppColors.primary.withOpacity(0.15),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: added ? AppColors.primary : AppColors.textDark,
              fontSize: 13,
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),

      // Danh sách dịch vụ đã thêm
      ..._services.asMap().entries.map((e) => _buildServiceRow(e.key, e.value)),

      // Nút thêm dịch vụ tuỳ chỉnh
      TextButton.icon(
        onPressed: _addCustomService,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Thêm dịch vụ khác'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    ]);
  }

  Widget _buildServiceRow(int index, _ServiceEntry entry) {
    final isPreset =
        _kServicePresets.any((p) => p['name'] == entry.serviceName);
    final label = isPreset
        ? _kServicePresets
            .firstWhere((p) => p['name'] == entry.serviceName)['label'] as String
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: isPreset
                ? Text(label!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14))
                : TextFormField(
                    initialValue: entry.serviceName,
                    decoration: const InputDecoration(
                      labelText: 'Tên dịch vụ',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => entry.serviceName = v,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
                  ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _removeService(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          // Đơn giá
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Đơn giá (₫)',
                isDense: true,
                border: OutlineInputBorder(),
                suffixText: '₫',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập giá' : null,
            ),
          ),
          const SizedBox(width: 10),
          // Đơn vị
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: entry.unit,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Đơn vị',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'kWh', child: Text('kWh')),
                DropdownMenuItem(value: 'person', child: Text('người')),
                DropdownMenuItem(value: 'month', child: Text('tháng')),
              ],
              onChanged: (v) => setState(() {
                entry.unit = v!;
                entry.isMetered = v == 'kWh';
              }),
            ),
          ),
          const SizedBox(width: 10),
          // Tính theo số
          Column(children: [
            const Text('Theo số', style: TextStyle(fontSize: 11)),
            Switch(
              value: entry.isMetered,
              onChanged: (v) => setState(() => entry.isMetered = v),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
        ]),
      ]),
    );
  }
}
