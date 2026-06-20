import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/shared_prefs_service.dart';
import '../../constants/app_constants.dart';
import '../agent/agent_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'forgot_password.dart';
import '../../widgets/custom_feedback.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _db = DatabaseService();
  bool _isAdminMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastLoginMode();
  }

  void _loadLastLoginMode() {
    final lastMode = SharedPrefsService.getLastLoginMode();
    if (lastMode == AppConstants.apiRoleAdmin) {
      _prefillAdmin();
    } else {
      _prefillAgent();
    }
  }

  void _prefillAgent() {
    setState(() {
      _isAdminMode = false;
      // _idController.text = '';
      // _passwordController.text = '';
    });
    SharedPrefsService.saveLastLoginMode(AppConstants.apiRoleAgent);
  }

  void _prefillAdmin() {
    setState(() {
      _isAdminMode = true;
      // _idController.text = '';
      // _passwordController.text = '';
    });
    SharedPrefsService.saveLastLoginMode(AppConstants.apiRoleAdmin);
  }

  void _handleLogin() async {
    final email = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      CustomFeedback.showFeedbackDialog(
        context,
        title: 'Required Fields',
        message: 'Please enter both email and password.',
        type: 'warning',
        confirmLabel: 'OK',
        showCancel: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _db.login(email, password, isAdmin: _isAdminMode);
      if (success) {
        SharedPrefsService.saveLastLoginMode(
          _isAdminMode ? AppConstants.apiRoleAdmin : AppConstants.apiRoleAgent,
        );
        _navigateToDashboard();
      } else {
        _showErrorDialog('Login failed. Please check your credentials.');
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _showErrorDialog(errorMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    CustomFeedback.showFeedbackDialog(
      context,
      title: 'Authentication Error',
      message: message,
      type: 'error',
      confirmLabel: 'OK',
      showCancel: false,
    );
  }

  void _navigateToDashboard() {
    Widget target = _db.currentRole == AppConstants.roleAdmin
        ? const AdminDashboard()
        : const AgentDashboard();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // App Branding
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppTheme.appLogo,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  // Text(
                  //   AppTheme.appName,
                  //   style: TextStyle(
                  //     fontSize: 28,
                  //     fontWeight: FontWeight.w800,
                  //     color: AppTheme.primary,
                  //     letterSpacing: -0.5,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                ],
              ),
              const SizedBox(height: 16),
              // Title & Subtitle
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to access your dashboard.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),

              // Role Selector Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _prefillAgent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isAdminMode
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                            boxShadow: !_isAdminMode
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Field Agent',
                            style: TextStyle(
                              color: !_isAdminMode
                                  ? AppTheme.primary
                                  : AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _prefillAdmin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isAdminMode
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                            boxShadow: _isAdminMode
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Agency Admin',
                            style: TextStyle(
                              color: _isAdminMode
                                  ? AppTheme.primary
                                  : AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Fields
                  Text(
                    'EMAIL ADDRESS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _idController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(LucideIcons.mail, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'SECURITY PASSWORD',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

              // Forgot Password link
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton(
              //     onPressed: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => const ForgotPasswordScreen(),
              //         ),
              //       );
              //     },
              //     child: const Text(
              //       'Forgot Password?',
              //       style: TextStyle(
              //         color: AppTheme.primary,
              //         fontWeight: FontWeight.bold,
              //         fontSize: 14,
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'SIGN IN PROTOCOL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
}
