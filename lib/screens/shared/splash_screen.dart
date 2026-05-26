import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _progressController;
  late Animation<double> _iconFade;
  late Animation<double> _textFade;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _iconFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _progressController.forward();
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFFDDE4F5), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _iconFade,
                child: Column(
                  children: [
                    // Shield icon container
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        AppTheme.appIcon,
                        color: AppTheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Logo text
                    FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          const Text(
                            AppTheme.appName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Field Agent Terminal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Secure • Compliant • Efficient',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 75),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progress.value,
                              backgroundColor: AppTheme.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Initializing...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                              Text(
                                '${(_progress.value * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              // Security badge
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 55),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.lock,
                        size: 14, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text(
                      '256-bit encrypted · RBI compliant',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
