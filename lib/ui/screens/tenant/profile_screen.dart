import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../login_screen.dart';

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
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _guardians = [];
  bool _isLoading = true;

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
          _guardians = guardiansSnap.docs.map((d) => d.data()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải hồ sơ: $e');
      setState(() => _isLoading = false);
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
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
                        const Text(
                          'Thông tin tài khoản',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
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
                  const SizedBox(height: 32),

                  // Guardian Card
                  if (_guardians.isNotEmpty)
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
                          const Text(
                            'Người giám hộ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._guardians.map((g) => _buildGuardianItem(g)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

