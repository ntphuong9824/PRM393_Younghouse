import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _picker = ImagePicker();
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _guardians = [];
  bool _isLoading = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _authService.getOrCreateUserProfile(user);
        final guardiansSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('guardians')
            .get();
        setState(() {
          _userProfile = profile;
          _guardians = guardiansSnap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải hồ sơ: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeAvatar() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 60);
    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();
    final base64Str = base64Encode(bytes);

    if (base64Str.length > 700 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 500KB.')),
      );
      return;
    }

    setState(() => _isUploadingAvatar = true);
    try {
      final dataUrl = 'data:image/jpeg;base64,$base64Str';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'avatar_url': dataUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
      setState(() {
        _userProfile = {...?_userProfile, 'avatar_url': dataUrl};
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật ảnh: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                debugPrint('Lỗi đăng xuất: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi đăng xuất: $e')),
                );
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tài khoản',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  _buildAvatar(),

                  const SizedBox(height: 20),

                  // User Name
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  if (_userProfile?['email'] != null)
                    Text(
                      _userProfile!['email'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Banner chờ xác nhận
                  if (_userProfile != null &&
                      !(_userProfile!['is_profile_confirmed'] as bool? ?? false))
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hồ sơ đang chờ admin xác nhận. Bạn không thể chỉnh sửa cho đến khi được xác nhận.',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Profile Information Card
                  Container(
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Thông tin tài khoản',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (_userProfile != null &&
                                (_userProfile!['is_profile_confirmed'] as bool? ??
                                    false))
                              InkWell(
                                onTap: () async {
                                  final updated = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfileScreen(
                                        userId: widget.userId,
                                        profile: _userProfile!,
                                        guardians: _guardians,
                                      ),
                                    ),
                                  );
                                  if (updated == true) _loadUserProfile();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_outlined,
                                      size: 20, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Email', _userProfile?['email'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        _buildInfoRow('Họ và tên', _userProfile?['full_name'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        _buildInfoRow('Số điện thoại', _userProfile?['phone'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Ngày sinh',
                          _userProfile?['date_of_birth'] != null
                              ? _formatDate(_userProfile!['date_of_birth'])
                              : 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildIdNumberRow(_userProfile?['id_number'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Trạng thái xác nhận',
                          (_userProfile?['is_profile_confirmed'] ?? false)
                              ? 'Đã xác nhận'
                              : 'Chưa xác nhận',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Guardian Card
                  Container(
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Người giám hộ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (_userProfile != null &&
                                (_userProfile!['is_profile_confirmed'] as bool? ??
                                    false))
                              InkWell(
                                onTap: () async {
                                  final updated = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfileScreen(
                                        userId: widget.userId,
                                        profile: _userProfile!,
                                        guardians: _guardians,
                                      ),
                                    ),
                                  );
                                  if (updated == true) _loadUserProfile();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_outlined,
                                      size: 20, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_guardians.isEmpty)
                          const Text(
                            'Chưa có thông tin người giám hộ',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ..._guardians.map((g) => _buildGuardianItem(g)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Đổi mật khẩu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()),
                      ),
                      icon: const Icon(Icons.lock_reset,
                          color: AppColors.primary),
                      label: const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    final url = _userProfile?['avatar_url'] as String?;
    ImageProvider? imageProvider;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        imageProvider = MemoryImage(base64Decode(url.split(',').last));
      } else {
        imageProvider = NetworkImage(url);
      }
    }
    return GestureDetector(
      onTap: _isUploadingAvatar ? null : _changeAvatar,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                : null,
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isUploadingAvatar
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt,
                      size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianItem(Map<String, dynamic> guardian) {
    final relationship = guardian['relationship'] == 'bo' ? 'Bố' : 'Mẹ';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            relationship,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          _buildInfoRow('Họ tên', guardian['full_name'] ?? 'N/A'),
          const SizedBox(height: 4),
          _buildInfoRow('Số điện thoại', guardian['phone'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildIdNumberRow(String idNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Số CCCD',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        GestureDetector(
          onTap: idNumber != 'N/A' ? _showCccdImages : null,
          child: Row(
            children: [
              Text(
                idNumber,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: idNumber != 'N/A' ? AppColors.primary : AppColors.textDark,
                  decoration: idNumber != 'N/A' ? TextDecoration.underline : null,
                ),
              ),
              if (idNumber != 'N/A') ...[
                const SizedBox(width: 4),
                const Icon(Icons.image_outlined, size: 16, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showCccdImages() {
    final frontUrl = _userProfile?['id_front_url'] as String?;
    final backUrl = _userProfile?['id_back_url'] as String?;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ảnh CCCD',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (frontUrl != null) ...[
                const Text('Mặt trước', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildCccdImage(frontUrl),
                ),
                const SizedBox(height: 16),
              ],
              if (backUrl != null) ...[
                const Text('Mặt sau', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildCccdImage(backUrl),
                ),
              ],
              if (frontUrl == null && backUrl == null)
                const Text('Chưa có ảnh CCCD'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCccdImage(String url) {
    try {
      if (url.startsWith('data:image')) {
        // base64 data URL: "data:image/jpeg;base64,<data>"
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text('Không tải được ảnh'));
      } else {
        return Image.network(url, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text('Không tải được ảnh'));
      }
    } catch (_) {
      return const Text('Không tải được ảnh');
    }
  }

  String _formatDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = (timestamp as dynamic).toDate();
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}

