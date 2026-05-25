import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_feedback.dart';

class OTPScreen extends StatefulWidget {
  final String destination;
  final VoidCallback onVerified;

  const OTPScreen({
    super.key,
    required this.destination,
    required this.onVerified,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  // Timer State
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Simulate auto receiving SMS OTP code '7890' after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final code = ['7', '8', '9', '0'];
        for (var i = 0; i < 4; i++) {
          _controllers[i].text = code[i];
        }
        FocusScope.of(context).unfocus();
        CustomFeedback.showToast(
          context,
          'Simulated SMS Auto-fill: 7890 loaded!',
          type: 'success',
        );
      }
    });
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _verifyOTP() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 4) {
      widget.onVerified();
    } else {
      CustomFeedback.showToast(
        context,
        'Please fill all 4 digits.',
        type: 'error',
      );
    }
  }

  void _resendCode() {
    if (!_canResend) return;
    
    _startTimer();
    
    // Clear fields
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    CustomFeedback.showToast(
      context,
      'Resending new verification token SMS...',
      type: 'info',
    );

    // Re-simulate auto filling new token '3142' after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final code = ['3', '1', '4', '2'];
        for (var i = 0; i < 4; i++) {
          _controllers[i].text = code[i];
        }
        FocusScope.of(context).unfocus();
        CustomFeedback.showToast(
          context,
          'Simulated SMS Auto-fill: 3142 loaded!',
          type: 'success',
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Security Authorization'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Shield padlock visual at the top
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              Text(
                'Enter Security Token',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'A one-time verification passcode has been transmitted via secure cellular channel to ${widget.destination}. Please enter the 4-digit code.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),

              // Styled 4 Digit Input Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60,
                    height: 60,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _controllers[index].text.isNotEmpty
                              ? AppTheme.primary
                              : AppTheme.outlineVariant.withOpacity(0.8),
                          width: _controllers[index].text.isNotEmpty ? 2.0 : 1.0,
                        ),
                        boxShadow: _controllers[index].text.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to update outline border style
                          if (value.isNotEmpty && index < 3) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (index == 3 && value.isNotEmpty) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),

              // Verify button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: _verifyOTP,
                child: const Text(
                  'VERIFY SECURITY CODE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Interactive Resend timer and button option
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _canResend
                      ? TextButton.icon(
                          key: const ValueKey('resend_active'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: _resendCode,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'Resend Verification Token',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Container(
                          key: const ValueKey('resend_countdown'),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
