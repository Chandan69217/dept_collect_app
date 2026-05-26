import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';

class BiometricAuth extends StatefulWidget {
  final VoidCallback onSuccess;

  const BiometricAuth({
    super.key,
    required this.onSuccess,
  });

  @override
  State<BiometricAuth> createState() => _BiometricAuthState();
}

class _BiometricAuthState extends State<BiometricAuth>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  final _db = DatabaseService();
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);

    // Auto-success after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSuccess = true;
        });
        _controller.stop();

        // Delay success callback to let user see success tick
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            widget.onSuccess();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFaceId = _db.faceIdEnabled;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge * 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            _isSuccess
                ? 'AUTHENTICATION SECURED'
                : 'BIOMETRIC SCANNING',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isSuccess ? AppTheme.success : AppTheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            _isSuccess
                ? 'Identity verified successfully. Transitioning...'
                : 'Place your face/fingerprint in focus for verification',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 48),

          // Scanning Animation Area
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSuccess
                      ? AppTheme.successContainer
                      : AppTheme.primaryContainer.withOpacity(0.05),
                  border: Border.all(
                    color: _isSuccess
                        ? AppTheme.success
                        : AppTheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: _isSuccess ? 1.0 : _pulseAnimation.value,
                    child: Icon(
                      _isSuccess
                          ? LucideIcons.circleCheck
                          : (isFaceId ? LucideIcons.scanFace : LucideIcons.fingerprint),
                      size: 56,
                      color: _isSuccess ? AppTheme.success : AppTheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
