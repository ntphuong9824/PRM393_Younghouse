import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/guardian_model.dart';
import '../../services/local_db_service.dart';
import '../../services/notification_service.dart';
import 'tenant/main_screen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final String userId;
  final String phone;
  final String? initialFullName;
  const ProfileCompletionScreen({
    super.key,
    required this.userId,
    required this.phone,
    this.initialFullName,
  });

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _idNumberController = TextEditingController();
  DateTime? _selectedDob;

  // Người giám hộ
  final _fatherNameController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _idFrontImage;
  File? _idBackImage;
  String? _idFrontDataUrl;
  String? _idBackDataUrl;

  bool _isSaving = false;
  bool _isLoadingProfile = true;
  String? _landlordId;

  @override
  void initState() {
    super.initState();
    final seededName = widget.initialFullName?.trim() ?? '';
    if (seededName.isNotEmpty) {
      _fullNameController.text = seededName;
    }
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final data = snapshot.data();
      final fullName = ((data?['full_name'] as String?) ??
              (data?['fullName'] as String?) ??
              widget.initialFullName ??
              '')
          .trim();

      if (!mounted) return;
      setState(() {
        _fullNameController.text = fullName;
        _landlordId = data?['landlord_id'] as String?;
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String? _validateVietnameseIdNumber(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Vui lòng nhập Số CCCD/CMND';

    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 9 && digitsOnly.length != 12) {
      return 'CCCD/CMND phải gồm 9 hoặc 12 chữ số';
    }
    return null;
  }

  String? _validateGuardianPhone(String? value, {required bool required}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return required ? 'Vui lòng nhập Số điện thoại' : null;
    }

    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 9 || digitsOnly.length > 11) {
      return 'Số điện thoại phải có từ 9 đến 11 chữ số';
    }
    return null;
  }

  Future<void> _pickIdImage(bool isFront) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked == null || !mounted) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() {
        if (isFront) {
          _idFrontImage = file;
          _idFrontDataUrl = dataUrl;
        } else {
          _idBackImage = file;
          _idBackDataUrl = dataUrl;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _selectedDob = picked;
      _dobController.text = _formatDate(picked);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _idNumberController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Họ và tên chưa có dữ liệu. Vui lòng liên hệ quản trị viên.'),
        ),
      );
      return;
    }
    if (_idFrontDataUrl == null || _idBackDataUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chụp đủ ảnh CCCD mặt trước và mặt sau.')),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final user = UserModel(
        id: widget.userId,
        email: '',
        phone: widget.phone,
        fullName: _fullNameController.text.trim(),
        role: 'tenant',
        idNumber: _idNumberController.text.trim(),
        idFrontUrl: _idFrontDataUrl,
        idBackUrl: _idBackDataUrl,
        dateOfBirth: _selectedDob,
        isProfileConfirmed: false,
        createdAt: now,
        updatedAt: now,
      );

      final local = LocalDbService();

      // Lưu user vào SQLite
      final userMap = user.toSqlite();
      userMap['is_synced'] = 0;
      await local.upsert('users', userMap);

      // Lưu người giám hộ
      final guardians = <GuardianModel>[];
      if (_fatherNameController.text.trim().isNotEmpty) {
        guardians.add(GuardianModel(
          id: '${widget.userId}_father',
          userId: widget.userId,
          fullName: _fatherNameController.text.trim(),
          phone: _fatherPhoneController.text.trim(),
          relationship: 'bố',
        ));
      }
      if (_motherNameController.text.trim().isNotEmpty) {
        guardians.add(GuardianModel(
          id: '${widget.userId}_mother',
          userId: widget.userId,
          fullName: _motherNameController.text.trim(),
          phone: _motherPhoneController.text.trim(),
          relationship: 'mẹ',
        ));
      }

      for (final g in guardians) {
        await local.upsert('guardians', g.toSqlite());
      }

      // Sync lên Firestore (optional — bỏ qua nếu lỗi permission)
      try {
        final batch = FirebaseFirestore.instance.batch();
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(widget.userId),
          user.toFirestore(),
          SetOptions(merge: true),
        );
        for (final g in guardians) {
          batch.set(
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('guardians')
                .doc(g.id),
            g.toFirestore(),
          );
        }
        await batch.commit();

        // Gửi thông báo cho admin
        if (_landlordId != null && _landlordId!.isNotEmpty) {
          await NotificationService().sendNotification(
            title: 'Hồ sơ cần xác nhận',
            message:
                '${user.fullName} vừa hoàn thiện hồ sơ và cần được xác nhận.',
            targetUserId: _landlordId,
            metadata: {'tenantId': widget.userId, 'type': 'profile_update'},
          );
        }
      } catch (_) {
        // Firestore permission-denied — đã lưu local, tiếp tục
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              userId: widget.userId,
              userName: user.fullName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
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
        title: const Text("Hoàn thiện hồ sơ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isLoadingProfile
            ? const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Thông tin cá nhân",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 16),
              _field(
                _fullNameController,
                "Họ và tên",
                Icons.person,
                hint: 'Tên được tạo bởi quản trị viên',
                readOnly: true,
                canRequestFocus: false,
                enableInteractiveSelection: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDob,
                validator: (_) =>
                    _selectedDob == null ? 'Vui lòng chọn Ngày sinh' : null,
                decoration: InputDecoration(
                  labelText: 'Ngày sinh',
                  hintText: 'Chọn ngày sinh',
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _field(
                _idNumberController,
                "Số CCCD/CMND",
                Icons.badge,
                keyboardType: TextInputType.number,
                validator: _validateVietnameseIdNumber,
              ),
              const SizedBox(height: 16),
              _idImageCard(
                title: 'Ảnh CCCD mặt trước',
                imageFile: _idFrontImage,
                onTap: () => _pickIdImage(true),
              ),
              const SizedBox(height: 12),
              _idImageCard(
                title: 'Ảnh CCCD mặt sau',
                imageFile: _idBackImage,
                onTap: () => _pickIdImage(false),
              ),

              const SizedBox(height: 32),
              const Text("Thông tin người giám hộ",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 4),
              const Text("Bắt buộc ít nhất 1 người",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),

              // Bố
              _guardianCard(
                title: "Bố",
                icon: Icons.male,
                nameCtrl: _fatherNameController,
                phoneCtrl: _fatherPhoneController,
                required: true,
              ),
              const SizedBox(height: 16),

              // Mẹ
              _guardianCard(
                title: "Mẹ",
                icon: Icons.female,
                nameCtrl: _motherNameController,
                phoneCtrl: _motherPhoneController,
                required: false,
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isLoadingProfile) ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("HOÀN TẤT ĐĂNG KÝ",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guardianCard({
    required String title,
    required IconData icon,
    required TextEditingController nameCtrl,
    required TextEditingController phoneCtrl,
    required bool required,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (!required)
              const Text(' (tuỳ chọn)',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          _field(nameCtrl, "Họ tên $title", Icons.person, required: required),
          const SizedBox(height: 12),
          _field(phoneCtrl, "Số điện thoại $title", Icons.phone,
              keyboardType: TextInputType.phone,
              required: required,
              validator: (v) => _validateGuardianPhone(v, required: required)),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
    bool required = true,
    bool readOnly = false,
    bool canRequestFocus = true,
    bool enableInteractiveSelection = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      readOnly: readOnly,
      canRequestFocus: canRequestFocus,
      enableInteractiveSelection: enableInteractiveSelection,
      validator: validator ??
          (required
              ? (v) => v == null || v.isEmpty ? 'Vui lòng nhập $label' : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        suffixIcon: readOnly
            ? const Icon(Icons.lock_outline, color: Colors.grey, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _idImageCard({
    required String title,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: imageFile == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey),
                        SizedBox(height: 8),
                            Text('Nhấn để chọn ảnh từ thư viện'),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(imageFile, fit: BoxFit.cover),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
