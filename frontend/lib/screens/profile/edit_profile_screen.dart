/// EditProfileScreen - Chỉnh sửa hồ sơ cá nhân with API Integration
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/colors.dart';
import '../../services/user_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  
  int _yearlyGoal = 24;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController.text = user.fullName;
      _bioController.text = user.bio ?? '';
      _emailController.text = user.email;
      // Load reading goal from user settings if available
      _yearlyGoal = 24; // Default, could be from user.readingGoal
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      await _userService.updateProfile(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        readingGoal: _yearlyGoal.toString(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật hồ sơ'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa hồ sơ',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Lưu',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryStart,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Avatar
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final user = state is AuthAuthenticated ? state.user : null;
                      return Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primaryStart.withValues(alpha: 0.2),
                              backgroundImage: user?.avatarUrl != null
                                  ? NetworkImage(user!.avatarUrl!)
                                  : null,
                              child: user?.avatarUrl == null
                                  ? Text(
                                      user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryStart,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryStart,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Họ và tên',
                    hint: 'Nhập họ tên của bạn',
                    validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Bio
                  _buildTextField(
                    controller: _bioController,
                    label: 'Giới thiệu',
                    hint: 'Viết vài dòng về bản thân...',
                    maxLines: 3,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Email (readonly)
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: '',
                    enabled: false,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Reading goal
                  _buildGoalSection(isDark),
                  
                  const SizedBox(height: 32),
                  
                  // Danger zone
                  _buildDangerZone(isDark),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      setState(() => _isLoading = true);
      
      final url = await _userService.uploadAvatar(image.path);
      
      if (url != null) {
        // Update profile with new avatar URL
        await _userService.updateProfile(avatarUrl: url);
        
        // Refresh local user data via Bloc
        if (mounted) {
          // Trigger a refresh of the auth state/user profile
          // Since we don't have a direct "refresh" event in AuthBloc visible here, 
          // we rely on the fact that updateProfile updates the backend. 
          // Ideally AuthBloc should be re-fetched or updated.
          // For now, let's just show success message.
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật ảnh đại diện'), backgroundColor: AppColors.success),
          );
          
          // Force reload user data
          _loadUserData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload ảnh: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: !enabled,
            fillColor: enabled ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: AppColors.primaryStart),
              const SizedBox(width: 12),
              Text(
                'Mục tiêu đọc năm nay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                onPressed: _yearlyGoal > 1 
                    ? () => setState(() => _yearlyGoal--) 
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Text(
                  '$_yearlyGoal cuốn sách',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryStart,
                  ),
                ),
              ),
              IconButton(
                onPressed: _yearlyGoal < 100 
                    ? () => setState(() => _yearlyGoal++) 
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _yearlyGoal.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: AppColors.primaryStart,
            onChanged: (v) => setState(() => _yearlyGoal = v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vùng nguy hiểm',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            onTap: () {
              context.push('/profile/edit/password');
            },
            leading: const Icon(Icons.lock_outline, color: AppColors.error),
            title: Text(
              'Đổi mật khẩu',
              style: GoogleFonts.plusJakartaSans(color: AppColors.error),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.error),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            onTap: () => _confirmDeleteAccount(context),
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              'Xóa tài khoản',
              style: GoogleFonts.plusJakartaSans(color: AppColors.error),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.error),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(
          'Bạn có chắc muốn xóa tài khoản? Tất cả dữ liệu sẽ bị mất vĩnh viễn và không thể khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call delete account API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
