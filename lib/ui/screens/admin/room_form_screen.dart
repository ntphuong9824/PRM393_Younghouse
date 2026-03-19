import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room_model.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/app_form_field.dart';
import '../../widgets/app_save_button.dart';

class RoomFormScreen extends StatefulWidget {
  final String propertyId;
  final RoomModel? room;
  const RoomFormScreen({super.key, required this.propertyId, this.room});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _roomNumberCtrl = TextEditingController(text: widget.room?.roomNumber);
  late final _floorCtrl = TextEditingController(text: widget.room?.floor.toString() ?? '1');
  late final _areaCtrl = TextEditingController(text: widget.room?.areaSqm.toString() ?? '');
  late final _priceCtrl = TextEditingController(text: widget.room?.basePrice.toString() ?? '');
  late final _depositCtrl = TextEditingController(text: widget.room?.depositAmount.toString() ?? '');
  late final _descCtrl = TextEditingController(text: widget.room?.description ?? '');
  String _status = 'vacant';
  List<File> _newImages = [];
  List<String> _existingImages = [];
  bool _isSaving = false;

  bool get _isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _status = widget.room!.status;
      _existingImages = List.from(widget.room!.images);
    }
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose(); _floorCtrl.dispose(); _areaCtrl.dispose();
    _priceCtrl.dispose(); _depositCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() => _newImages.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final provider = context.read<PropertyProvider>();
      if (_isEdit) {
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
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
      } catch (_) {
        // Fall through to broken image icon.
      }
      return const SizedBox(
        width: 80,
        height: 80,
        child: Icon(Icons.broken_image),
      );
    }

    return Image.network(
      imageSource,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox(
        width: 80,
        height: 80,
        child: Icon(Icons.broken_image),
      ),
    );
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: AppFormField(controller: _roomNumberCtrl, label: 'Số phòng', icon: Icons.meeting_room)),
              const SizedBox(width: 12),
              Expanded(child: AppFormField(controller: _floorCtrl, label: 'Tầng', icon: Icons.layers, isNumber: true)),
            ]),
            const SizedBox(height: 16),
            AppFormField(controller: _areaCtrl, label: 'Diện tích (m²)', icon: Icons.square_foot, isNumber: true, required: false),
            const SizedBox(height: 16),
            AppFormField(controller: _priceCtrl, label: 'Giá thuê (₫)', icon: Icons.attach_money, isNumber: true),
            const SizedBox(height: 16),
            AppFormField(controller: _depositCtrl, label: 'Tiền cọc (₫)', icon: Icons.savings, isNumber: true),
            const SizedBox(height: 16),
            AppFormField(controller: _descCtrl, label: 'Mô tả / Tiện nghi', icon: Icons.description, required: false, maxLines: 3),
            const SizedBox(height: 16),

            // Trạng thái
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                prefixIcon: const Icon(Icons.toggle_on, color: AppColors.primary),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'vacant', child: Text('Còn trống')),
                DropdownMenuItem(value: 'occupied', child: Text('Đã có người thuê')),
                DropdownMenuItem(value: 'maintenance', child: Text('Đang bảo trì')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 24),

            // Ảnh phòng
            const Text('Ảnh phòng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              // Ảnh cũ
              ..._existingImages.map((url) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildExistingImage(url),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _existingImages.remove(url)),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )),
              // Ảnh mới chọn
              ..._newImages.map((file) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _newImages.remove(file)),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )),
              // Nút thêm ảnh
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.add_photo_alternate, color: AppColors.primary),
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
}
