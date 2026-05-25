import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../shared/login_screen.dart';
import 'security_settings.dart';

class AgentProfileScreen extends StatefulWidget {
  final bool isEmbedded;

  const AgentProfileScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> with SingleTickerProviderStateMixin {
  final db = DatabaseService();
  bool _pushNotificationsEnabled = true;
  late AnimationController _radialController;

  @override
  void initState() {
    super.initState();
    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _radialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, child) {
        final agent = db.currentUser;
        if (agent == null) return const SizedBox();

        // Calculate progress percentage
        final double percentage = agent.assignedTarget == 0
            ? 0.0
            : (agent.collectedAmount / agent.assignedTarget);
        final String metPercent = (percentage * 100).toStringAsFixed(0);

        final content = SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Profile Card with blur effect background decoration
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Decorative Blur Glow Behind
                  Positioned(
                    top: -10,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryContainer.withOpacity(0.2),
                      ),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),

                  // Hero Core Column
                  CustomBentoCard(
                    padding: 24.0,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // Smart Avatar with verified checkmark badge overlay
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundImage: NetworkImage(agent.avatarUrl),
                                backgroundColor: AppTheme.surfaceContainerLow,
                              ),
                            ),
                            // Verified badge overlay
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1B5E20), // Smart Emerald Green
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        Text(
                          agent.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DCP-88429-XM',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  letterSpacing: 1.0,
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Symmetric Sub-Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.outlineVariant.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'REGION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.secondary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'North East',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.outlineVariant.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'SCORE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.secondary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '98.4%',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1B5E20), // Green score
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Bento Stats Grid
              Row(
                children: [
                  // Visits Today
                  Expanded(
                    child: CustomBentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.pin_drop_outlined,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Visits Today',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '14',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Collections Made
                  Expanded(
                    child: CustomBentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.currency_rupee,
                              color: Color(0xFF1B5E20),
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Collections Made',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹12,450',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Royal Blue Targets recovery Progress card with rotating Radial progress indicator
              CustomBentoCard(
                backgroundColor: AppTheme.primary,
                borderSide: BorderSide.none,
                padding: 20.0,
                backgroundDecoration: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF0047BB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MONTHLY RECOVERY TARGET',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.65),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '82% Achieved',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${agent.collectedAmount.toStringAsFixed(0)} collected of ₹${agent.assignedTarget.toStringAsFixed(0)} target',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Custom rotating SVG / Painter Target Progress Circle
                    AnimatedBuilder(
                      animation: _radialController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CustomPaint(
                                painter: TargetProgressPainter(
                                  percentage: percentage * _radialController.value,
                                ),
                              ),
                            ),
                            Text(
                              '$metPercent%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Settings menu panel
              CustomBentoCard(
                padding: 4.0,
                child: Column(
                  children: [
                    // Security & Privacy
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 20),
                      ),
                      title: const Text(
                        'Security & Privacy',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                      ),
                      subtitle: const Text('PIN setup, Face ID & encryption', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.secondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),

                    // Push Notifications Toggle
                    SwitchListTile(
                      activeColor: AppTheme.primary,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.notifications_active_outlined, color: AppTheme.primary, size: 20),
                      ),
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                      ),
                      subtitle: const Text('Instant alerts on verification', style: TextStyle(fontSize: 12)),
                      value: _pushNotificationsEnabled,
                      onChanged: (val) {
                        setState(() {
                          _pushNotificationsEnabled = val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _pushNotificationsEnabled
                                  ? 'Push notifications activated.'
                                  : 'Push notifications silenced.',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),

                    // Helpdesk
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.headset_mic_outlined, color: AppTheme.primary, size: 20),
                      ),
                      title: const Text(
                        'Protocol Support Helpdesk',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                      ),
                      subtitle: const Text('Contact tech-ops support desk', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.secondary),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Support Desk Contact'),
                            content: const Text(
                              'Establish encrypted voice call or direct ticket with Mumbai Tech-Ops Support Desk?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Support ticket created. Tech-Ops will contact you.')),
                                  );
                                },
                                child: const Text('ESTABLISH'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 5. Logout Security Session Block
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Terminate Session?'),
                      content: const Text(
                        'This will terminate your secure offline data caching and log out Miller from this terminal.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                          onPressed: () {
                            Navigator.pop(context);
                            db.logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('TERMINATE SESSION'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'LOGOUT SECURE SESSION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        );

        if (widget.isEmbedded) return content;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('My Profile'),
          ),
          body: content,
        );
      },
    );
  }
}

class TargetProgressPainter extends CustomPainter {
  final double percentage;

  TargetProgressPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Paint
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * 3.1415926535 * (percentage > 1.0 ? 1.0 : percentage);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2, // Start at the top (-90 degrees)
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TargetProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
