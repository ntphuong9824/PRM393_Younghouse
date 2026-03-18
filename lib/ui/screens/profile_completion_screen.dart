import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/guardian_model.dart';
import '../../services/local_db_service.dart';
import 'tenant/main_screen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final String userId;
  final String phone;
  const ProfileCompletionScreen({
    super.key,
    required this.userId,
    required this.phone,
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

  bool _isSaving = false;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
        child: Form(
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
              _field(_fullNameController, "Họ và tên", Icons.person),
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
              _field(_idNumberController, "Số CCCD/CMND", Icons.badge),

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
                  onPressed: _isSaving ? null : _submitProfile,
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
              keyboardType: TextInputType.phone, required: required),
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
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: required
          ? (v) => v == null || v.isEmpty ? 'Vui lòng nhập $label' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
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
}
