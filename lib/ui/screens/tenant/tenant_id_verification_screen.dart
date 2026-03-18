import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import 'main_screen.dart';

class TenantIdVerificationScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String phone;
  final Map<String, dynamic>? existingProfile;

  const TenantIdVerificationScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.phone,
    this.existingProfile,
  });

  @override
  State<TenantIdVerificationScreen> createState() =>
      _TenantIdVerificationScreenState();
}

class _TenantIdVerificationScreenState extends State<TenantIdVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dobController = TextEditingController();
  final _idNumberController = TextEditingController();
  
  File? _idFrontImage;
  File? _idBackImage;
  String? _idFrontUrl;
  String? _idBackUrl;
  
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingProfile != null) {
      final data = widget.existingProfile!;
      
      // Load date of birth
      if (data['date_of_birth'] != null) {
        final dob = (data['date_of_birth'] as Timestamp).toDate();
        _dobController.text = '${dob.day}/${dob.month}/${dob.year}';
      }
      
      // Load ID number
      if (data['id_number'] != null) {
        _idNumberController.text = data['id_number'] as String;
      }
      
      // Store existing URLs
      if (data['id_front_url'] != null) {
        _idFrontUrl = data['id_front_url'] as String;
      }
      if (data['id_back_url'] != null) {
        _idBackUrl = data['id_back_url'] as String;
      }
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isFront) {
            _idFrontImage = File(pickedFile.path);
          } else {
            _idBackImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  Future<String> _uploadImage(File imageFile, String imageName) async {
    try {
      final fileName = '${widget.userId}/$imageName';
      final ref = _storage.ref('id_images/$fileName');
      
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    // Validate images
    if (_idFrontImage == null && _idFrontUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh mặt trước CCCD')),
      );
      return;
    }

    if (_idBackImage == null && _idBackUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh mặt sau CCCD')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Parse date of birth
      final parts = _dobController.text.trim().split('/');
      if (parts.length != 3) {
        throw Exception('Định dạng ngày sinh không hợp lệ');
      }

      final dob = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      // Upload images if new ones selected
      String frontUrl = _idFrontUrl ?? '';
      String backUrl = _idBackUrl ?? '';

      if (_idFrontImage != null) {
        frontUrl = await _uploadImage(_idFrontImage!, 'id_front.jpg');
      }

      if (_idBackImage != null) {
        backUrl = await _uploadImage(_idBackImage!, 'id_back.jpg');
      }

      // Update user profile in Firestore
      await _db.collection('users').doc(widget.userId).set(
        {
          'date_of_birth': Timestamp.fromDate(dob),
          'id_number': _idNumberController.text.trim(),
          'id_front_url': frontUrl,
          'id_back_url': backUrl,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
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
        title: const Text(
          'Xác thực thông tin nhân dân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
              // Warning message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vui lòng cung cấp đầy đủ thông tin nhân dân để hoàn tất xác thực tài khoản',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Date of birth
              Text(
                'Ngày sinh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dobController,
                keyboardType: TextInputType.datetime,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập ngày sinh' : null,
                decoration: InputDecoration(
                  hintText: 'DD/MM/YYYY',
                  prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ID Number
              Text(
                'Số CCCD/CMND',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idNumberController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập số CCCD/CMND' : null,
                decoration: InputDecoration(
                  hintText: 'Nhập số CCCD/CMND',
                  prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ID Front Photo
              Text(
                'Ảnh mặt trước CCCD/CMND',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _buildImagePickerCard(
                isSelected: _idFrontImage != null || _idFrontUrl != null,
                imageFile: _idFrontImage,
                imageUrl: _idFrontUrl,
                onTap: () => _pickImage(true),
              ),
              const SizedBox(height: 24),

              // ID Back Photo
              Text(
                'Ảnh mặt sau CCCD/CMND',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _buildImagePickerCard(
                isSelected: _idBackImage != null || _idBackUrl != null,
                imageFile: _idBackImage,
                imageUrl: _idBackUrl,
                onTap: () => _pickImage(false),
              ),
              const SizedBox(height: 40),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'XÁC THỰC',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerCard({
    required bool isSelected,
    required File? imageFile,
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              )
            : imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    ),
                  )
                : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Nhấn để chọn ảnh',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

