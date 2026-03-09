import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'main_screen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal Info
  final _fullNameController = TextEditingController();
  final _cccdController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Parents Info
  final _fatherNameController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherPhoneController = TextEditingController();

  void _submitProfile() {
    if (_formKey.currentState!.validate()) {
      // Simulate saving to database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Hoàn thiện hồ sơ", style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text(
                "Thông tin cá nhân",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              _buildTextField(_fullNameController, "Họ và tên khách thuê", Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_dobController, "Ngày tháng năm sinh", Icons.calendar_today, hint: "DD/MM/YYYY"),
              const SizedBox(height: 16),
              _buildTextField(_cccdController, "Số CCCD/CMND", Icons.badge),
              const SizedBox(height: 16),
              _buildTextField(_addressController, "Địa chỉ thường trú", Icons.home, maxLines: 2),
              
              const SizedBox(height: 32),
              const Text(
                "Thông tin người thân (Bắt buộc)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              
              // Father
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildTextField(_fatherNameController, "Họ tên bố", Icons.male),
                    const SizedBox(height: 12),
                    _buildTextField(_fatherPhoneController, "Số điện thoại bố", Icons.phone, keyboardType: TextInputType.phone),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Mother
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildTextField(_motherNameController, "Họ tên mẹ", Icons.female),
                    const SizedBox(height: 12),
                    _buildTextField(_motherPhoneController, "Số điện thoại mẹ", Icons.phone, keyboardType: TextInputType.phone),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "HOÀN TẤT ĐĂNG KÝ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {String? hint, TextInputType? keyboardType, int maxLines = 1}
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
