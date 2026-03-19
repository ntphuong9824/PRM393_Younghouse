import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _authService = AuthService();
  bool _isConfirming = false;
  bool _isDeleting = false;
  late bool _isConfirmed;

  @override
  void initState() {
    super.initState();
    _isConfirmed = widget.user.isProfileConfirmed;
  }

  Future<void> _confirmProfile() async {
    setState(() => _isConfirming = true);
    try {
      await _authService.confirmUserProfile(widget.user.id);
      if (mounted) {
        setState(() => _isConfirmed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận hồ sơ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá tài khoản'),
        content: Text(
            'Bạn có chắc muốn xoá tài khoản "${widget.user.fullName}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _authService.deleteUserProfile(widget.user.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết người dùng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isDeleting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xoá tài khoản',
              onPressed: _deleteProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar + tên
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: const Icon(Icons.person, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                u.fullName.isEmpty ? 'Người dùng' : u.fullName,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConfirmed
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isConfirmed ? Colors.green : Colors.orange,
                  ),
                ),
                child: Text(
                  _isConfirmed ? 'Đã xác nhận hồ sơ' : 'Chờ xác nhận hồ sơ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isConfirmed ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Thông tin cơ bản
          _sectionTitle('Thông tin cơ bản'),
          _infoCard([
            _infoRow(Icons.email_outlined, 'Email', u.email),
            _infoRow(Icons.phone_outlined, 'Số điện thoại',
                u.phone.isEmpty ? '—' : u.phone),
            if (u.dateOfBirth != null)
              _infoRow(Icons.cake_outlined, 'Ngày sinh',
                  DateFormatter.format(u.dateOfBirth!)),
            _infoRow(Icons.badge_outlined, 'Số CCCD/CMND',
                u.idNumber?.isEmpty ?? true ? '—' : u.idNumber!),
            _infoRow(Icons.calendar_today_outlined, 'Ngày tạo',
                DateFormatter.format(u.createdAt)),
          ]),
          const SizedBox(height: 16),

          // Ảnh CCCD
          if (u.idFrontUrl != null || u.idBackUrl != null) ...[
            _sectionTitle('Ảnh CCCD/CMND'),
            Row(children: [
              if (u.idFrontUrl != null)
                Expanded(
                    child: _idImageCard('Mặt trước', u.idFrontUrl!)),
              if (u.idFrontUrl != null && u.idBackUrl != null)
                const SizedBox(width: 12),
              if (u.idBackUrl != null)
                Expanded(child: _idImageCard('Mặt sau', u.idBackUrl!)),
            ]),
            const SizedBox(height: 16),
          ],

          // Người giám hộ
          _sectionTitle('Người giám hộ'),
          _GuardianSection(userId: u.id),
          const SizedBox(height: 32),

          // Nút confirm
          if (!_isConfirmed)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isConfirming ? null : _confirmProfile,
                icon: _isConfirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                label: Text(
                  _isConfirming ? 'Đang xác nhận...' : 'XÁC NHẬN HỒ SƠ',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isDeleting ? null : _deleteProfile,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('XOÁ TÀI KHOẢN',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
      );

  Widget _infoCard(List<Widget> rows) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(children: rows),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _idImageCard(String label, String dataUrl) {
    Widget imageWidget;
    if (dataUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(dataUrl.split(',').last);
        imageWidget = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        imageWidget = const Icon(Icons.broken_image, color: Colors.grey);
      }
    } else {
      imageWidget = Image.network(dataUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
        ),
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: AspectRatio(aspectRatio: 16 / 9, child: imageWidget),
        ),
      ]),
    );
  }
}

class _GuardianSection extends StatelessWidget {
  final String userId;
  const _GuardianSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('guardians')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text('Chưa có thông tin người giám hộ',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final name = d['full_name'] ?? '—';
              final phone = d['phone'] ?? '—';
              final rel = d['relationship'] == 'bo' ? 'Bố' : 'Mẹ';
              return ListTile(
                leading: const Icon(Icons.people_outline,
                    color: AppColors.primary, size: 20),
                title: Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text('$rel · $phone',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                dense: true,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
