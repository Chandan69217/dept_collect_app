import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../shared/login_screen.dart';
import 'security_settings.dart';
import 'agent_edit_profile_screen.dart';

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
              // 1. Sleek Compact Hero Profile Card
              CustomBentoCard(
                padding: 14.0,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Ultra-Premium highly styled compact Squircle avatar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AgentEditProfileScreen()),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      Color(0xFF00C6FF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      agent.avatarUrl,
                                      width: 62,
                                      height: 62,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 62,
                                        height: 62,
                                        color: AppTheme.surfaceContainerLow,
                                        child: const Icon(LucideIcons.user, color: AppTheme.secondary, size: 24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Elegant miniature verified badge overlay at bottom right
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1B5E20), // Smart Emerald Green
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.check,
                                      size: 9,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Identity Name, ID & Active Pills
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agent.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      'DCP-88429-XM',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                            letterSpacing: 0.4,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
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
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppTheme.outlineVariant),
                    const SizedBox(height: 12),

                    // Symmetric Statistics Elements
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.mapPin,
                                  size: 16,
                                  color: AppTheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'REGION',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'North East',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 28, color: AppTheme.outlineVariant),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.star,
                                  size: 16,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SCORE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '98.4%',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Bento Stats Grid
              Row(
                children: [
                  // Visits Today
                  Expanded(
                    child: CustomBentoCard(
                      padding: 12.0,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.pinOff,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Visits Today',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '14',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.onSurface,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Collections Made
                  Expanded(
                    child: CustomBentoCard(
                      padding: 12.0,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.indianRupee,
                              color: Color(0xFF1B5E20),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Collections Made',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹12,450',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.onSurface,
                                      ),
                                ),
                              ],
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
                    // Edit Profile
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.user, color: AppTheme.primary, size: 20),
                      ),
                      title: const Text(
                        'Edit Profile Details',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                      ),
                      subtitle: const Text('Change name, email, phone & photo', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(LucideIcons.chevronRight, size: 20, color: AppTheme.secondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AgentEditProfileScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),

                    // Security & Privacy
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.shieldCheck, color: AppTheme.primary, size: 20),
                      ),
                      title: const Text(
                        'Security & Privacy',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                      ),
                      subtitle: const Text('PIN setup, Face ID & encryption', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(LucideIcons.chevronRight, size: 20, color: AppTheme.secondary),
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
                        child: const Icon(LucideIcons.bellRing, color: AppTheme.primary, size: 20),
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
                        child: const Icon(LucideIcons.headset, color: AppTheme.primary, size: 20),
                      ),
                      title: const Text(
                        'Protocol Support Helpdesk',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                      ),
                      subtitle: const Text('Contact tech-ops support desk', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(LucideIcons.chevronRight, size: 20, color: AppTheme.secondary),
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
                icon: const Icon(LucideIcons.logOut, size: 18),
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
