import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../register_screen.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final String landlordId;
  const UserManagementScreen({super.key, required this.landlordId});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _authService = AuthService();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý người dùng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RegisterScreen(adminId: widget.landlordId)),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Tạo tài khoản'),
      ),
      body: Column(children: [
        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, SĐT, email...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Danh sách
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _authService.streamAllTenants(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Không tải được danh sách user: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              var docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? const [],
              )
                ..retainWhere((doc) {
                  final data = doc.data();
                  final rawLandlordId = data['landlord_id'];
                  if (rawLandlordId == null) return true;
                  final normalized = rawLandlordId is String
                      ? rawLandlordId.trim()
                      : rawLandlordId.toString().trim();
                  if (normalized.isEmpty) return true;
                  return normalized == widget.landlordId;
                })
                ..sort((a, b) {
                  final aTs = a.data()['created_at'];
                  final bTs = b.data()['created_at'];
                  final aDate = aTs is Timestamp
                      ? aTs.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = bTs is Timestamp
                      ? bTs.toDate()
                      : DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

              // Lọc theo query
              if (_query.isNotEmpty) {
                docs = docs.where((doc) {
                  final d = doc.data();
                  final name =
                      (d['full_name'] as String? ?? '').toLowerCase();
                  final phone =
                      (d['phone'] as String? ?? '').toLowerCase();
                  final email =
                      (d['email'] as String? ?? '').toLowerCase();
                  return name.contains(_query) ||
                      phone.contains(_query) ||
                      email.contains(_query);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    _query.isNotEmpty
                        ? 'Không tìm thấy kết quả'
                        : 'Chưa có tài khoản tenant nào',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final user = UserModel.fromFirestore(docs[index]);
                  final name = (data['full_name'] as String?)?.trim();
                  final phone = (data['phone'] as String?)?.trim();
                  final email = (data['email'] as String?)?.trim();
                  final isConfirmed =
                      data['is_profile_confirmed'] == true;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              UserDetailScreen(user: user)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withOpacity(0.15),
                          child: const Icon(Icons.person,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (name == null || name.isEmpty)
                                    ? 'Người dùng'
                                    : name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              if (phone != null && phone.isNotEmpty)
                                Text('SDT: $phone',
                                    style: const TextStyle(fontSize: 13)),
                              if (email != null && email.isNotEmpty)
                                Text('Email: $email',
                                    style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                isConfirmed
                                    ? 'Hồ sơ: đã xác nhận'
                                    : 'Hồ sơ: chờ xác nhận',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isConfirmed
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.grey),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
