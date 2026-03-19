import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/contract_service.dart';

class AdminCreateContractScreen extends StatefulWidget {
  final String landlordId;

  const AdminCreateContractScreen({
    super.key,
    required this.landlordId,
  });

  @override
  State<AdminCreateContractScreen> createState() =>
      _AdminCreateContractScreenState();
}

class _AdminCreateContractScreenState extends State<AdminCreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ContractService();
  final _termsController = TextEditingController();

  List<AdminRoomOption> _rooms = const [];
  List<AdminTenantOption> _tenants = const [];
  final Set<String> _selectedCoTenantIds = <String>{};
  String? _coTenantPickerValue;
  String? _selectedRoomId;
  String? _selectedTenantId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _contractFileDataUrl;
  String? _contractFileName;
  String? _contractFileMimeType;
  int? _contractFileSizeBytes;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day);
    _loadInitialData();
  }

  @override
  void dispose() {
    _termsController.dispose();
    super.dispose();
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<void> _pickContractFile() async {
    const maxBytes = 700 * 1024; // Firestore doc has size limit, keep attachment small.
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
    } catch (_) {
      // Some environments fail to initialize FilePicker platform instance.
      final fallback = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (fallback == null) return;

      final bytes = await File(fallback.path).readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không đọc được file đã chọn')),
        );
        return;
      }
      if (bytes.length > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File quá lớn. Vui lòng chọn file <= 700KB')),
        );
        return;
      }

      final fileName = fallback.name.trim().isEmpty ? 'contract_image.jpg' : fallback.name.trim();
      final mimeType = _guessMimeType(fileName);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

      setState(() {
        _contractFileDataUrl = dataUrl;
        _contractFileName = fileName;
        _contractFileMimeType = mimeType;
        _contractFileSizeBytes = bytes.length;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiết bị không hỗ trợ chọn PDF. Đã chuyển sang chọn ảnh từ thư viện.')),
      );
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      final file = File(picked.path!);
      bytes = await file.readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đọc được file đã chọn')),
      );
      return;
    }

    if (bytes.length > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File quá lớn. Vui lòng chọn file <= 700KB')),
      );
      return;
    }

    final fileName = (picked.name).trim().isEmpty ? 'contract_file' : picked.name.trim();
    final mimeType = _guessMimeType(fileName);
    final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

    setState(() {
      _contractFileDataUrl = dataUrl;
      _contractFileName = fileName;
      _contractFileMimeType = mimeType;
      _contractFileSizeBytes = bytes!.length;
    });
  }

  void _removeContractFile() {
    setState(() {
      _contractFileDataUrl = null;
      _contractFileName = null;
      _contractFileMimeType = null;
      _contractFileSizeBytes = null;
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getVacantRoomsByLandlord(widget.landlordId),
        _service.getTenantsByLandlord(widget.landlordId),
      ]);

      final rooms = results[0] as List<AdminRoomOption>;
      final tenants = results[1] as List<AdminTenantOption>;

      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _tenants = tenants;
        _selectedRoomId = rooms.isNotEmpty ? rooms.first.id : null;
        _selectedTenantId = tenants.isNotEmpty ? tenants.first.id : null;
        _selectedCoTenantIds
          ..clear()
          ..remove(_selectedTenantId);
        _coTenantPickerValue = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được dữ liệu tạo hợp đồng: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && !_endDate!.isAfter(_startDate!)) {
          _endDate = DateTime(picked.year + 1, picked.month, picked.day);
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _createContract() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null || _selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng và người thuê')),
      );
      return;
    }
    if (_startDate == null || _endDate == null || !_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu')),
      );
      return;
    }

    final coTenants = _selectedCoTenantIds
        .where((id) => id != _selectedTenantId)
        .toList();

    setState(() => _isSaving = true);
    try {
      final contractId = await _service.createContractTransactional(
        landlordId: widget.landlordId,
        roomId: _selectedRoomId!,
        tenantId: _selectedTenantId!,
        startDate: _startDate!,
        endDate: _endDate!,
        terms: _termsController.text.trim(),
        coTenants: coTenants,
        pdfUrl: _contractFileDataUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo hợp đồng thành công: $contractId')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tạo được hợp đồng: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_isSaving && _rooms.isNotEmpty && _tenants.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo hợp đồng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin hợp đồng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_rooms.isEmpty)
                      _infoBanner('Không có phòng trống để tạo hợp đồng.'),
                    if (_tenants.isEmpty)
                      _infoBanner('Không có tenant nào thuộc admin này.'),
                    if (_rooms.isEmpty || _tenants.isEmpty)
                      const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey('room-${_selectedRoomId ?? 'none'}'),
                      initialValue: _selectedRoomId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Phòng',
                        prefixIcon: Icon(Icons.meeting_room, color: AppColors.primary),
                        border: OutlineInputBorder(),
                      ),
                      items: _rooms
                          .map((r) => DropdownMenuItem<String>(
                                value: r.id,
                                child: Text(r.displayLabel),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRoomId = v),
                      validator: (v) => v == null ? 'Vui lòng chọn phòng' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey('tenant-${_selectedTenantId ?? 'none'}'),
                      initialValue: _selectedTenantId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Người thuê',
                        prefixIcon: Icon(Icons.person, color: AppColors.primary),
                        border: OutlineInputBorder(),
                      ),
                      items: _tenants
                          .map((t) => DropdownMenuItem<String>(
                                value: t.id,
                                child: Text(t.displayLabel),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedTenantId = v;
                        if (v != null) {
                          _selectedCoTenantIds.remove(v);
                        }
                        _coTenantPickerValue = null;
                      }),
                      validator: (v) => v == null ? 'Vui lòng chọn người thuê' : null,
                    ),
                    const SizedBox(height: 14),
                    _dateField(
                      label: 'Ngày bắt đầu',
                      value: _startDate,
                      onTap: () => _pickDate(isStart: true),
                    ),
                    const SizedBox(height: 14),
                    _dateField(
                      label: 'Ngày kết thúc',
                      value: _endDate,
                      onTap: () => _pickDate(isStart: false),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _termsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Điều khoản hợp đồng',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) {
                          return 'Vui lòng nhập điều khoản hợp đồng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'co-tenant-${_selectedTenantId ?? 'none'}-${_selectedCoTenantIds.length}',
                      ),
                      initialValue: _coTenantPickerValue,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Co-tenant',
                        prefixIcon: Icon(Icons.groups, color: AppColors.primary),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Chọn thêm người ở cùng'),
                      items: _tenants
                          .where((t) => t.id != _selectedTenantId)
                          .map((t) => DropdownMenuItem<String>(
                                value: t.id,
                                child: Text(t.displayLabel),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null || value == _selectedTenantId) return;
                        setState(() {
                          _selectedCoTenantIds.add(value);
                          _coTenantPickerValue = null;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_selectedCoTenantIds.isEmpty)
                      const Text(
                        'Chưa chọn co-tenant',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _tenants
                            .where((t) => _selectedCoTenantIds.contains(t.id))
                            .map((t) => Chip(
                                  label: Text(t.displayLabel,
                                      style: const TextStyle(fontSize: 13)),
                                  avatar: const Icon(Icons.person,
                                      size: 16, color: AppColors.primary),
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.08),
                                  side: BorderSide(
                                      color:
                                          AppColors.primary.withOpacity(0.3)),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => setState(
                                      () => _selectedCoTenantIds.remove(t.id)),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 14),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'File hợp đồng (ảnh/PDF)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_file, color: AppColors.primary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_contractFileName == null)
                            const Text(
                              'Chưa có file được chọn',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            Text(
                              '$_contractFileName (${_formatFileSize(_contractFileSizeBytes ?? 0)})',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          if (_contractFileMimeType != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _contractFileMimeType!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickContractFile,
                                icon: const Icon(Icons.upload_file),
                                label: Text(_contractFileName == null ? 'Chọn file' : 'Đổi file'),
                              ),
                              if (_contractFileName != null)
                                OutlinedButton.icon(
                                  onPressed: _removeContractFile,
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  label: const Text(
                                    'Xoá file',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_selectedRoomId != null)
                      _roomPriceHint(_selectedRoomId!),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: canSubmit ? _createContract : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'TẠO HỢP ĐỒNG',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoBanner(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Text(text, style: const TextStyle(color: Colors.deepOrange)),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month, color: AppColors.primary),
          border: const OutlineInputBorder(),
        ),
        child: Text(value == null ? 'Chọn ngày' : _formatDate(value)),
      ),
    );
  }

  Widget _roomPriceHint(String roomId) {
    final selected = _rooms.where((r) => r.id == roomId).toList();
    if (selected.isEmpty) return const SizedBox.shrink();
    final room = selected.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giá thuê tháng (từ phòng): ${room.basePrice.toStringAsFixed(0)}'),
          Text('Tiền cọc (từ phòng): ${room.depositAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          const Text(
            'Khi tạo hợp đồng, room sẽ tự động chuyển sang trạng thái occupied.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

}



