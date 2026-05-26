import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_feedback.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSaving = false;
  bool _isSaved = false;

  // Real-time requirement flags
  bool _reqLength = false;
  bool _reqNumber = false;
  bool _reqSpecial = false;

  late final AnimationController _lockController;
  late final Animation<double> _lockScale;

  @override
  void initState() {
    super.initState();
    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _lockScale = CurvedAnimation(
      parent: _lockController,
      curve: Curves.elasticOut,
    );
    _lockController.forward();

    _newPasswordController.addListener(_validateRequirements);
  }

  void _validateRequirements() {
    final val = _newPasswordController.text;
    setState(() {
      _reqLength = val.length >= 8;
      _reqNumber = RegExp(r'\d').hasMatch(val);
      _reqSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val);
    });
  }

  bool get _allRequirementsMet => _reqLength && _reqNumber && _reqSpecial;

  void _handleReset() {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      CustomFeedback.showToast(
        context,
        'Please fill in all password fields.',
        type: 'error',
      );
      return;
    }

    if (!_allRequirementsMet) {
      CustomFeedback.showToast(
        context,
        'Password must meet all security requirements.',
        type: 'error',
      );
      return;
    }

    if (newPass != confirmPass) {
      CustomFeedback.showToast(
        context,
        'Passwords do not match. Please re-enter.',
        type: 'error',
      );
      return;
    }

    setState(() => _isSaving = true);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        // Navigate to login, removing entire auth stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        CustomFeedback.showToast(
          context,
          'Password updated. Please log in with your new credentials.',
          type: 'success',
        );
      });
    });
  }

  @override
  void dispose() {
    _lockController.dispose();
    _newPasswordController.removeListener(_validateRequirements);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reset Password'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  Text(
                    'Create New Password',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your new password must be different from previous passwords.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Lock Reset Animated Icon
                  Center(
                    child: ScaleTransition(
                      scale: _lockScale,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _isSaved
                                  ? LucideIcons.checkCircle
                                  : LucideIcons.lockKeyhole,
                              color: _isSaved ? Colors.green : AppTheme.primary,
                              size: 44,
                            ),
                          ),
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.outlineVariant,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.shieldCheck,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // New Password Field
                  const Text(
                    'NEW PASSWORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: !_isNewPasswordVisible,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      hintStyle: TextStyle(
                        color: AppTheme.secondary.withOpacity(0.5),
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.lockKeyhole,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordVisible
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          size: 20,
                          color: AppTheme.outline,
                        ),
                        onPressed: () => setState(
                          () => _isNewPasswordVisible = !_isNewPasswordVisible,
                        ),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  const Text(
                    'CONFIRM NEW PASSWORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Repeat new password',
                      hintStyle: TextStyle(
                        color: AppTheme.secondary.withOpacity(0.5),
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.lockKeyhole,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          size: 20,
                          color: AppTheme.outline,
                        ),
                        onPressed: () => setState(
                          () => _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible,
                        ),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password Requirements Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PASSWORD REQUIREMENTS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRequirement(
                          LucideIcons.checkCircle,
                          'At least 8 characters long',
                          _reqLength,
                        ),
                        const SizedBox(height: 8),
                        _buildRequirement(
                          LucideIcons.checkCircle,
                          'Contains at least one number',
                          _reqNumber,
                        ),
                        const SizedBox(height: 8),
                        _buildRequirement(
                          LucideIcons.checkCircle,
                          'Contains one special character (!@#\$)',
                          _reqSpecial,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSaved
                              ? Colors.green
                              : AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: AppTheme.primary.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: (_isSaving || _isSaved)
                            ? null
                            : _handleReset,
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'SECURING...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              )
                            : _isSaved
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.checkCircle, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'PASSWORD RESET!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'RESET PASSWORD',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(LucideIcons.lockOpen, size: 16),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Secured with AES-256 field-grade encryption',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(IconData icon, String label, bool met) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 250),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: met ? AppTheme.primary : AppTheme.onSurfaceVariant,
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              key: ValueKey(met),
              size: 16,
              color: met ? AppTheme.primary : AppTheme.outlineVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
