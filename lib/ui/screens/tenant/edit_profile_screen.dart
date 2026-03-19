import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/notification_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> guardians;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.profile,
    this.guardians = const [],
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  final _notificationService = NotificationService();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _idNumberCtrl;
  late final TextEditingController _fatherNameCtrl;
  late final TextEditingController _fatherPhoneCtrl;
  late final TextEditingController _motherNameCtrl;
  late final TextEditingController _motherPhoneCtrl;

  DateTime? _dateOfBirth;

  // CCCD
  File? _idFrontFile;
  File? _idBackFile;
  String? _idFrontUrl;
  String? _idBackUrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _fullNameCtrl = TextEditingController(
        text: widget.profile['full_name'] as String? ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.profile['phone'] as String? ?? '');
    _idNumberCtrl = TextEditingController(
        text: widget.profile['id_number'] as String? ?? '');

    final dob = widget.profile['date_of_birth'];
    if (dob is Timestamp) _dateOfBirth = dob.toDate();
    if (dob is DateTime) _dateOfBirth = dob;

    _idFrontUrl = widget.profile['id_front_url'] as String?;
    _idBackUrl = widget.profile['id_back_url'] as String?;

    final father = widget.guardians.firstWhere(
      (g) => (g['relationship'] as String? ?? '') == 'bo',
      orElse: () => <String, dynamic>{},
    );
    final mother = widget.guardians.firstWhere(
      (g) => (g['relationship'] as String? ?? '') == 'me',
      orElse: () => <String, dynamic>{},
    );

    _fatherNameCtrl =
        TextEditingController(text: (father['full_name'] as String?) ?? '');
    _fatherPhoneCtrl =
        TextEditingController(text: (father['phone'] as String?) ?? '');
    _motherNameCtrl =
        TextEditingController(text: (mother['full_name'] as String?) ?? '');
    _motherPhoneCtrl =
        TextEditingController(text: (mother['phone'] as String?) ?? '');
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _idNumberCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherPhoneCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 10),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  // Giới hạn: base64 string tối đa ~700KB → file gốc ~500KB
  static const int _maxBase64Bytes = 700 * 1024;

  Future<void> _pickIdImage(bool isFront) async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 60);
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);

    if (base64Str.length > _maxBase64Bytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 500KB.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (isFront) {
        _idFrontFile = file;
      } else {
        _idBackFile = file;
      }
    });
  }

  Future<String> _toDataUrl(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final batch = _db.batch();
      final userRef = _db.collection('users').doc(widget.userId);

      // Profile + CCCD images
      final profileUpdates = <String, dynamic>{
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'id_number': _idNumberCtrl.text.trim(),
        'is_profile_confirmed': false,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (_dateOfBirth != null) {
        profileUpdates['date_of_birth'] = Timestamp.fromDate(_dateOfBirth!);
      }
      if (_idFrontFile != null) {
        profileUpdates['id_front_url'] = await _toDataUrl(_idFrontFile!);
      }
      if (_idBackFile != null) {
        profileUpdates['id_back_url'] = await _toDataUrl(_idBackFile!);
      }
      batch.update(userRef, profileUpdates);

      // Guardians
      void upsertGuardian({
        required String relationship,
        required String suffix,
        required String name,
        required String phone,
      }) {
        if (name.trim().isEmpty && phone.trim().isEmpty) return;
        final id = '${widget.userId}_$suffix';
        final data = <String, dynamic>{
          'id': id,
          'user_id': widget.userId,
          'full_name': name.trim(),
          'phone': phone.trim(),
          'relationship': relationship,
        };
        batch.set(_db.collection('guardians').doc(id), data);
        batch.set(userRef.collection('guardians').doc(id), data);
      }

      upsertGuardian(
        relationship: 'bo',
        suffix: 'father',
        name: _fatherNameCtrl.text,
        phone: _fatherPhoneCtrl.text,
      );
      upsertGuardian(
        relationship: 'me',
        suffix: 'mother',
        name: _motherNameCtrl.text,
        phone: _motherPhoneCtrl.text,
      );

      await batch.commit();

      // Gửi thông báo cho admin
      final landlordId = widget.profile['landlord_id'] as String?;
      if (landlordId != null && landlordId.isNotEmpty) {
        final tenantName = _fullNameCtrl.text.trim().isNotEmpty
            ? _fullNameCtrl.text.trim()
            : widget.profile['email'] as String? ?? 'Tenant';
        await _notificationService.sendNotification(
          title: 'Hồ sơ cần xác nhận',
          message: '$tenantName vừa cập nhật hồ sơ và cần được xác nhận.',
          targetUserId: landlordId,
          metadata: {'tenantId': widget.userId, 'type': 'profile_update'},
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Cập nhật thành công. Hồ sơ đang chờ admin xác nhận.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Thông tin cá nhân'),
              const SizedBox(height: 12),
              _card([
                _field(
                  controller: _fullNameCtrl,
                  label: 'Họ và tên',
                  icon: Icons.person_outline,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Vui lòng nhập họ tên'
                      : null,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _phoneCtrl,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _idNumberCtrl,
                  label: 'Số CCCD',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _dobField(),
              ]),

              const SizedBox(height: 24),
              _sectionLabel('Ảnh CCCD'),
              const SizedBox(height: 12),
              _card([
                _idImagePicker(
                  label: 'Mặt trước',
                  file: _idFrontFile,
                  existingUrl: _idFrontUrl,
                  onTap: () => _pickIdImage(true),
                ),
                const SizedBox(height: 16),
                _idImagePicker(
                  label: 'Mặt sau',
                  file: _idBackFile,
                  existingUrl: _idBackUrl,
                  onTap: () => _pickIdImage(false),
                ),
              ]),

              const SizedBox(height: 24),
              _sectionLabel('Người giám hộ'),
              const SizedBox(height: 8),
              _guardianSubLabel('Bố'),
              const SizedBox(height: 8),
              _card([
                _field(
                  controller: _fatherNameCtrl,
                  label: 'Họ và tên',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _fatherPhoneCtrl,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      _validateGuardianPhone(v, _fatherNameCtrl.text),
                ),
              ]),
              const SizedBox(height: 16),
              _guardianSubLabel('Mẹ'),
              const SizedBox(height: 8),
              _card([
                _field(
                  controller: _motherNameCtrl,
                  label: 'Họ và tên',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _motherPhoneCtrl,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      _validateGuardianPhone(v, _motherNameCtrl.text),
                ),
              ]),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LƯU THAY ĐỔI',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _idImagePicker({
    required String label,
    required File? file,
    required String? existingUrl,
    required VoidCallback onTap,
  }) {
    Widget preview;
    if (file != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(file,
            height: 140, width: double.infinity, fit: BoxFit.cover),
      );
    } else if (existingUrl != null && existingUrl.isNotEmpty) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image(
          image: _buildImageProvider(existingUrl),
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _idPlaceholder(label),
        ),
      );
    } else {
      preview = _idPlaceholder(label);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              preview,
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Thay ảnh',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _idPlaceholder(String label) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 36, color: Colors.grey[400]),
          const SizedBox(height: 6),
          Text('Chọn ảnh $label',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  ImageProvider _buildImageProvider(String url) {
    if (url.startsWith('data:image')) {
      final base64Str = url.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(url);
  }

  String? _validateGuardianPhone(String? value, String name) {
    if (name.trim().isEmpty) return null;
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Vui lòng nhập số điện thoại';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 11) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      );

  Widget _guardianSubLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey),
      );

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, color: AppColors.primary),
        ),
        validator: validator,
      );

  Widget _dobField() {
    final label = _dateOfBirth != null
        ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
            '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
            '${_dateOfBirth!.year}'
        : 'Chưa chọn';
    return InkWell(
      onTap: _pickDateOfBirth,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ngày sinh',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.cake_outlined, color: AppColors.primary),
        ),
        child: Text(label),
      ),
    );
  }
}
