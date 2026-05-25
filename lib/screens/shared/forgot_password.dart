import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_feedback.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  void _handleReset() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      CustomFeedback.showToast(
        context,
        'Please enter your registered email address.',
        type: 'error',
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      CustomFeedback.showToast(
        context,
        'Please enter a valid email format (e.g. agent@debtcollect.in).',
        type: 'error',
      );
      return;
    }

    // Show secure feedback dialog and navigate to OTP validation on confirm
    CustomFeedback.showFeedbackDialog(
      context,
      title: 'Verification Code Sent!',
      message: 'A 6-digit secure authentication code has been dispatched to $email. Please check your inbox.',
      type: 'success',
      confirmLabel: 'ENTER OTP',
      cancelLabel: 'CANCEL',
      onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              destination: email,
              onVerified: () {
                CustomFeedback.showToast(
                  context,
                  'Identity verified! Secure reset link dispatched.',
                  type: 'success',
                );
                Navigator.pop(context); // pop OTP screen
                Navigator.pop(context); // pop Forgot Password screen
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppTheme.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Instructional Header
                  Text(
                    'Forgot Password?',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your registered email below. We will send a 6-digit verification code to reset your account credentials.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hero Graphic (Abstract Corporate Style)
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.04),
                          AppTheme.primary.withOpacity(0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.08),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.primary.withOpacity(0.04),
                          ),
                        ),
                        Positioned(
                          left: -35,
                          bottom: -35,
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        // Core Lock Icon
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.06),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 44,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Input Section
                  const Text(
                    'REGISTERED EMAIL ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter your registered email ID',
                      prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20, color: AppTheme.primary),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Send Code Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: AppTheme.primary.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _handleReset,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'SEND VERIFICATION CODE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.send_rounded, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Back to Login link
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Footer support block
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.border.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Having trouble? ',
                          style: TextStyle(fontSize: 12, color: AppTheme.secondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            CustomFeedback.showToast(
                              context,
                              'Redirecting to Admin Support Helpdesk...',
                              type: 'info',
                            );
                          },
                          child: const Text(
                            'Contact Admin Support',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
