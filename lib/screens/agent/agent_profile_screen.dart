import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../shared/login_screen.dart';
import 'agent_edit_profile_screen.dart';
import '../../widgets/custom_feedback.dart';
import '../../config/field_mapping.dart';

class AgentProfileScreen extends StatefulWidget {
  final bool isEmbedded;

  const AgentProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen>
    with SingleTickerProviderStateMixin {
  final db = DatabaseService();
  late AnimationController _radialController;

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

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

        final int completedCases = agent.casesCount - agent.pendingVisitsCount;
        final double score = agent.casesCount == 0
            ? 100.0
            : (completedCases > 0
                  ? (completedCases / agent.casesCount) * 100.0
                  : 0.0);
        final String scorePercent = '${score.toStringAsFixed(1)}%';

        final Color scoreColor = score >= 80.0
            ? const Color(0xFF2E7D32)
            : (score >= 50.0 ? AppTheme.warning : AppTheme.error);
        final Color scoreBgColor = score >= 80.0
            ? const Color(0xFFE8F5E9)
            : (score >= 50.0
                  ? AppTheme.warningContainer
                  : AppTheme.errorContainer);

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
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AgentEditProfileScreen(),
                              ),
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
                                    child: agent.avatarUrl.isNotEmpty
                                        ? Image.network(
                                            agent.avatarUrl,
                                            width: 62,
                                            height: 62,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  final initials =
                                                      agent.name
                                                          .trim()
                                                          .isNotEmpty
                                                      ? agent.name
                                                            .trim()
                                                            .split(
                                                              RegExp(r'\s+'),
                                                            )
                                                            .map(
                                                              (s) => s[0]
                                                                  .toUpperCase(),
                                                            )
                                                            .take(2)
                                                            .join()
                                                      : 'A';
                                                  return Container(
                                                    width: 62,
                                                    height: 62,
                                                    color: AppTheme.primary
                                                        .withOpacity(0.08),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      initials,
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme.primary,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : Builder(
                                            builder: (context) {
                                              final initials =
                                                  agent.name.trim().isNotEmpty
                                                  ? agent.name
                                                        .trim()
                                                        .split(RegExp(r'\s+'))
                                                        .map(
                                                          (s) => s[0]
                                                              .toUpperCase(),
                                                        )
                                                        .take(2)
                                                        .join()
                                                  : 'A';
                                              return Container(
                                                width: 62,
                                                height: 62,
                                                color: AppTheme.primary
                                                    .withOpacity(0.08),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                              );
                                            },
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
                                      color: Color(
                                        0xFF1B5E20,
                                      ), // Smart Emerald Green
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
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.primary.withOpacity(
                                          0.1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'DCP-${agent.id.toUpperCase()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                            letterSpacing: 0.4,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: agent.isOnline
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFECEFF1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      agent.isOnline ? 'ACTIVE' : 'OFFLINE',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: agent.isOnline
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFF546E7A),
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
                                    agent.zone,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppTheme.outlineVariant,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: scoreBgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.star,
                                  size: 16,
                                  color: scoreColor,
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
                                    scorePercent,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: scoreColor,
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
                              LucideIcons.calendarClock,
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
                                  'Pending Visits',
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
                                  agent.pendingVisitsCount.toString(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
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
                                  _formatCurrency(agent.collectedAmount),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
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
                          Text(
                            '$metPercent% Achieved',
                            style: const TextStyle(
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
                                  percentage:
                                      percentage * _radialController.value,
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
              const SizedBox(height: 16),

              // 3.5 Security & Permission Clearance (Read-Only)
              CustomBentoCard(
                padding: 16.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'SECURITY & DATA CLEARANCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The following data access and operational clearances are set for your account by system administrators:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // General Capabilities
                    const Text(
                      'Operational Clearances',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildClearanceRow(
                      'Access Collections History',
                      agent.permissions['accessHistory'] ?? false,
                    ),
                    _buildClearanceRow(
                      'Customer Schedule Visit',
                      agent.permissions['editDetails'] ?? false,
                    ),
                    _buildClearanceRow(
                      'Approve Partial Payments',
                      agent.permissions['approvePartial'] ?? false,
                    ),

                    _buildClearanceRow(
                      'Remove Assigned Records',
                      agent.permissions['deleteRecords'] ?? false,
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppTheme.outlineVariant),
                    const SizedBox(height: 16),

                    // Field Access Visibility
                    const Text(
                      'Field Visibility Clearance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExcelFieldMapping.mapping.keys.map((fieldKey) {
                        final isGranted = agent.permissions[fieldKey] ?? false;
                        final label =
                            fieldKey[0].toUpperCase() +
                            fieldKey
                                .substring(1)
                                .replaceAllMapped(
                                  RegExp(r'[A-Z]'),
                                  (match) => ' ${match.group(0)}',
                                );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isGranted
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFECEFF1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isGranted
                                  ? const Color(0xFFC8E6C9)
                                  : const Color(0xFFCFD8DC),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isGranted
                                    ? LucideIcons.check
                                    : LucideIcons.lock,
                                size: 12,
                                color: isGranted
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF546E7A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isGranted
                                      ? const Color(0xFF1B5E20)
                                      : const Color(0xFF37474F),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                        child: const Icon(
                          LucideIcons.user,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Edit Profile Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Change name, email, phone & photo',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: AppTheme.secondary,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AgentEditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    // const Divider(height: 1, indent: 56),

                    // Security & Privacy
                    // ListTile(
                    //   leading: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       color: AppTheme.primary.withOpacity(0.08),
                    //       borderRadius: BorderRadius.circular(6),
                    //     ),
                    //     child: const Icon(LucideIcons.shieldCheck, color: AppTheme.primary, size: 20),
                    //   ),
                    //   title: const Text(
                    //     'Security & Privacy',
                    //     style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                    //   ),
                    //   subtitle: const Text('PIN setup, Face ID & encryption', style: TextStyle(fontSize: 12)),
                    //   trailing: const Icon(LucideIcons.chevronRight, size: 20, color: AppTheme.secondary),
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()),
                    //     );
                    //   },
                    // ),
                    // const Divider(height: 1, indent: 56),

                    // Push Notifications Toggle
                    // SwitchListTile(
                    //   activeColor: AppTheme.primary,
                    //   secondary: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       color: AppTheme.primary.withOpacity(0.08),
                    //       borderRadius: BorderRadius.circular(6),
                    //     ),
                    //     child: const Icon(LucideIcons.bellRing, color: AppTheme.primary, size: 20),
                    //   ),
                    //   title: const Text(
                    //     'Push Notifications',
                    //     style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                    //   ),
                    //   subtitle: const Text('Instant alerts on verification', style: TextStyle(fontSize: 12)),
                    //   value: _pushNotificationsEnabled,
                    //   onChanged: (val) {
                    //     setState(() {
                    //       _pushNotificationsEnabled = val;
                    //     });
                    //     CustomFeedback.showToast(
                    //       context,
                    //       _pushNotificationsEnabled
                    //           ? 'Push notifications activated.'
                    //           : 'Push notifications silenced.',
                    //       type: _pushNotificationsEnabled ? 'success' : 'info',
                    //     );
                    //   },
                    // ),
                    // const Divider(height: 1, indent: 56),

                    // Helpdesk
                    // ListTile(
                    //   leading: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       color: AppTheme.primary.withOpacity(0.08),
                    //       borderRadius: BorderRadius.circular(6),
                    //     ),
                    //     child: const Icon(LucideIcons.headset, color: AppTheme.primary, size: 20),
                    //   ),
                    //   title: const Text(
                    //     'Protocol Support Helpdesk',
                    //     style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
                    //   ),
                    //   subtitle: const Text('Contact tech-ops support desk', style: TextStyle(fontSize: 12)),
                    //   trailing: const Icon(LucideIcons.chevronRight, size: 20, color: AppTheme.secondary),
                    //   onTap: () {
                    //     CustomFeedback.showFeedbackDialog(
                    //       context,
                    //       title: 'Support Desk Contact',
                    //       message: 'Establish encrypted voice call or direct ticket with Mumbai Tech-Ops Support Desk?',
                    //       type: 'info',
                    //       confirmLabel: 'ESTABLISH',
                    //       onConfirm: () {
                    //         CustomFeedback.showToast(
                    //           context,
                    //           'Support ticket created. Tech-Ops will contact you.',
                    //           type: 'success',
                    //         );
                    //       },
                    //     );
                    //   },
                    // ),
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
                  CustomFeedback.showFeedbackDialog(
                    context,
                    title: 'Terminate Session?',
                    message:
                        'This will terminate your secure offline data caching and log out ${db.currentUser?.name ?? 'user'} from this terminal.',
                    type: 'error',
                    confirmLabel: 'TERMINATE',
                    onConfirm: () {
                      db.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
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
          appBar: AppBar(title: const Text('My Profile')),
          body: content,
        );
      },
    );
  }

  Widget _buildClearanceRow(String title, bool isCleared) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isCleared ? LucideIcons.check : LucideIcons.lock,
            size: 16,
            color: isCleared ? const Color(0xFF2E7D32) : AppTheme.secondary,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isCleared ? AppTheme.onSurface : AppTheme.secondary,
              fontWeight: isCleared ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
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

    final double sweepAngle =
        2 * 3.1415926535 * (percentage > 1.0 ? 1.0 : percentage);
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
