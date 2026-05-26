import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../widgets/custom_feedback.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _db = DatabaseService();
  bool _cameraPermission = true;
  bool _locationPermission = true;
  bool _isClearingCache = false;

  void _clearCache() {
    setState(() {
      _isClearingCache = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isClearingCache = false;
      });
      CustomFeedback.showToast(
        context,
        'Cache cleared successfully! 1.4 MB storage freed.',
        type: 'success',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Security & Privacy'),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // SECTION 1: ACCOUNT SECURITY
                // ==========================================
                _buildSectionHeader('ACCOUNT SECURITY'),
                const SizedBox(height: 8),
                CustomBentoCard(
                  padding: 8.0,
                  child: Column(
                    children: [
                      // Change PIN Tile
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(LucideIcons.keyRound, color: AppTheme.primary, size: 20),
                        ),
                        title: const Text(
                          'Change Security PIN',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                        ),
                        subtitle: const Text('Reset your 4-digit device PIN code', style: TextStyle(fontSize: 12)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        onTap: () {
                          _showPinResetDialog();
                        },
                      ),
                      const Divider(height: 1, indent: 56),

                      // Biometric Authentication switch
                      SwitchListTile(
                        activeColor: AppTheme.primary,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(LucideIcons.fingerprint, color: AppTheme.primary, size: 20),
                        ),
                        title: const Text(
                          'Biometric Authentication',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                        ),
                        subtitle: const Text('Enable Face ID or Touch ID sign-in', style: TextStyle(fontSize: 12)),
                        value: _db.biometricAuthEnabled,
                        onChanged: (val) {
                          _db.toggleBiometric(val);
                        },
                      ),

                      if (_db.biometricAuthEnabled) ...[
                        const Divider(height: 1, indent: 56),
                        // Face ID Protocol sub-toggle
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          secondary: const SizedBox(width: 36),
                          title: const Text(
                            'Use Face ID Protocol',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 13),
                          ),
                          value: _db.faceIdEnabled,
                          onChanged: (val) {
                            _db.toggleFaceId(val);
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        // Touch ID Protocol sub-toggle
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          secondary: const SizedBox(width: 36),
                          title: const Text(
                            'Use Touch ID Protocol',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 13),
                          ),
                          value: _db.touchIdEnabled,
                          onChanged: (val) {
                            _db.toggleTouchId(val);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 2: PRIVACY & DATA
                // ==========================================
                _buildSectionHeader('PRIVACY & DATA'),
                const SizedBox(height: 8),

                // Asymmetric side-by-side bento layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Bento Card: App Permissions status rows
                    Expanded(
                      flex: 11,
                      child: CustomBentoCard(
                        padding: 16.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'App Permissions',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Location Permission Status Row
                            _buildPermissionToggle(
                              icon: LucideIcons.mapPin,
                              label: 'Location',
                              value: _locationPermission,
                              onChanged: (val) {
                                setState(() {
                                  _locationPermission = val;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            // Camera Permission Status Row
                            _buildPermissionToggle(
                              icon: LucideIcons.camera,
                              label: 'Camera',
                              value: _cameraPermission,
                              onChanged: (val) {
                                setState(() {
                                  _cameraPermission = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right Bento Card: Gradient E2EE Data Security status card
                    Expanded(
                      flex: 12,
                      child: CustomBentoCard(
                        backgroundColor: AppTheme.primary,
                        borderSide: BorderSide.none,
                        padding: 16.0,
                        backgroundDecoration: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, Color(0xFF0047BB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.lock,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'E2EE ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'End-to-End Encrypted',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last verified: 2m ago',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Full-width Clear Storage Cache row with a crimson "Clear" action button
                CustomBentoCard(
                  padding: 12.0,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.database, color: AppTheme.secondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Storage Cache',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Temporary offline metrics: 1.4 MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Crimson clear button
                      SizedBox(
                        height: 32,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.errorContainer,
                            foregroundColor: AppTheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: _isClearingCache ? null : _clearCache,
                          child: _isClearingCache
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.error),
                                  ),
                                )
                              : const Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 3: DEVICE MANAGEMENT
                // ==========================================
                _buildSectionHeader('DEVICE MANAGEMENT'),
                const SizedBox(height: 8),

                // Active session bento card displaying iPhone 14 Pro Max
                CustomBentoCard(
                  padding: 16.0,
                  child: Row(
                    children: [
                      // Styled Active Device Container Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.smartphone,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Active device details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'iPhone 14 Pro Max',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'App Version 2.4.1',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Mumbai, IND',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Pulse Emerald Active Now Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFC8E6C9),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PulsingDot(),
                            SizedBox(width: 6),
                            Text(
                              'Active Now',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bottom security warning text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Icon(LucideIcons.shieldAlert, color: AppTheme.secondary.withOpacity(0.5), size: 20),
                      const SizedBox(height: 8),
                      Text(
                        'This terminal uses real-time locally encrypted vaults. Any modifications to biological signatures or access vectors will force a 2-minute recovery session lockout for security purposes.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: AppTheme.secondary.withOpacity(0.8),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppTheme.secondary,
            ),
      ),
    );
  }

  Widget _buildPermissionToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 20,
          width: 32,
          child: Switch(
            activeColor: AppTheme.primary,
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showPinResetDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Security PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a new 4-digit PIN to authorize collection overrides on this device.',
              style: TextStyle(fontSize: 13, color: AppTheme.secondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'NEW 4-DIGIT PIN',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                Navigator.pop(context);
                CustomFeedback.showToast(
                  context,
                  'Security Passcode PIN successfully updated!',
                  type: 'success',
                );
              } else {
                CustomFeedback.showToast(
                  context,
                  'PIN must be exactly 4 digits.',
                  type: 'error',
                );
              }
            },
            child: const Text('UPDATE PIN'),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1B5E20).withOpacity(1.0 - _pulseController.value),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(_pulseController.value),
                blurRadius: 4 * _pulseController.value,
                spreadRadius: 2 * _pulseController.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
