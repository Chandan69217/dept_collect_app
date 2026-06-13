import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_feedback.dart';
import '../../constants/app_constants.dart';

class AgentEditProfileScreen extends StatefulWidget {
  const AgentEditProfileScreen({super.key});

  @override
  State<AgentEditProfileScreen> createState() => _AgentEditProfileScreenState();
}

class _AgentEditProfileScreenState extends State<AgentEditProfileScreen> {
  final _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _avatarUrl;
  late String status;

  bool _isSaving = false;
  bool _isSaved = false;

  // Preset Portrait Avatars for user selection
  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150', // Executive Male
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', // Executive Female 1
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', // Executive Male 2
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', // Professional Female 2
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', // Professional Male 3
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150', // Professional Female 3
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150', // Senior Executive Male
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150', // Senior Executive Female
  ];

  @override
  void initState() {
    super.initState();
    final agent = _db.currentUser;
    _nameController = TextEditingController(text: agent?.name ?? '');
    _emailController = TextEditingController(text: agent?.email ?? '');
    _phoneController = TextEditingController(text: agent?.phone ?? '');
    _addressController = TextEditingController(text: agent?.address ?? '');
    _avatarUrl = agent?.avatarUrl ?? '';
    status = agent?.isOnline == true ? AppConstants.statusActive : AppConstants.statusInActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showAvatarSelector() {
    CustomFeedback.showFeedbackDialog(
      context,
      title: 'Select Profile Photo',
      message: '',
      type: 'info',
      showCancel: false,
      confirmLabel: 'CLOSE',
      customBody: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: _presetAvatars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final url = _presetAvatars[index];
            final isSelected = _avatarUrl == url;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _avatarUrl = url;
                });
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    width: 3.5,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(url),
                  backgroundColor: AppTheme.surfaceContainerLow,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final agentId = _db.currentUser?.id ?? '';
      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();
      final newPhone = _phoneController.text.trim();
      final newAddress = _addressController.text.trim();

      // Call the backend update API first
      await _db.updateAgentOnBackend(
        agentId: agentId,
        fullName: newName,
        email: newEmail,
        mobile: newPhone,
        status: status,
      );

      // Call the local update profile method to update state and save to SharedPreferences
      _db.updateAgentProfile(
        name: newName,
        email: newEmail,
        phone: newPhone,
        address: newAddress,
        avatarUrl: _avatarUrl,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });

        CustomFeedback.showToast(
          context,
          'Profile updated successfully!',
          type: 'success',
        );

        // Show direct premium feedback bar before pop-out
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e,stackTrace) {
      log("Update Error: $e");
      log("Stack Trace: $stackTrace");
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        CustomFeedback.showToast(
          context,
          'Failed to update profile: ${e.toString().replaceAll('Exception: ', '')}',
          type: 'error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = _db.currentUser;
    if (agent == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(

        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',

        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Profile Header Section with HSL Gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF8F9FF), Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Interactive Avatar Editor
                        GestureDetector(
                          onTap: _showAvatarSelector,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.outlineVariant,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(_avatarUrl),
                                  backgroundColor: AppTheme.surfaceContainerLow,
                                ),
                              ),
                              // Hover/Camera Camera Overlay Indicator
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black26,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                              // Circular bottom right edit pencil action button
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    LucideIcons.pencil,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Field Operations • v2.4.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Inputs list
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Input
                        _buildInputLabel('Full Name'),
                        _buildInputField(
                          controller: _nameController,
                          icon: LucideIcons.user,
                          hintText: 'Enter your full name',
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Email Input
                        _buildInputLabel('Email Address'),
                        _buildInputField(
                          controller: _emailController,
                          icon: LucideIcons.mail,
                          hintText: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!AppConstants.emailRegex.hasMatch(val.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Phone Input
                        _buildInputLabel('Phone Number'),
                        _buildInputField(
                          controller: _phoneController,
                          icon: LucideIcons.phone,
                          maxLength: 10,
                          hintText: 'Enter phone number',
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (!AppConstants.mobileRegex.hasMatch(
                              val.trim(),
                            )) {
                              return 'Enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Permanent Address Input
                        _buildInputLabel('Permanent Address'),
                        _buildInputField(
                          controller: _addressController,
                          icon: LucideIcons.mapPin,
                          hintText: 'Enter permanent address',
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 24),

                        // Preferences Clearances read-only card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Agent Clearance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Region Support Area',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                  Text(
                                    agent.zone,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.outlineVariant, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving || _isSaved ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaved
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF00328A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _isSaved
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF00328A).withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'SAVING...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ] else if (_isSaved) ...[
                        const Icon(LucideIcons.checkCheck, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'PROFILE UPDATED',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ] else ...[
                        const Icon(LucideIcons.checkCircle, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.secondary,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        counterText: "",
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppTheme.outline, size: 20),
      ),
    );
  }
}
