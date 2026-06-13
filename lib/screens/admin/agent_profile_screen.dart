import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../models/agent.dart';
import 'edit_permissions_screen.dart';
import '../../widgets/custom_feedback.dart';

class AgentProfileScreen extends StatelessWidget {
  final Agent agent;

  const AgentProfileScreen({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return ListenableBuilder(
      listenable: db,
      builder: (context, child) {
        // Find the most up-to-date agent details from shared state
        final activeAgent = db.agents.firstWhere(
          (a) => a.id == agent.id,
          orElse: () => agent,
        );

        final targetPercentage = activeAgent.assignedTarget == 0
            ? 0.88 // Fallback standard representation matching mockup
            : (activeAgent.collectedAmount / activeAgent.assignedTarget);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Agent Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section: Agent Identity
                _buildHeroCard(context, db, activeAgent),
                const SizedBox(height: 16),

                // Quick Stats Bento Grid
                _buildStatsBentoGrid(context, activeAgent, targetPercentage),
                const SizedBox(height: 16),

                // Performance Details
                _buildPerformanceDetails(context, activeAgent),
                const SizedBox(height: 20),

                // Quick Actions
                _buildQuickActionsRow(context, db, activeAgent),
                const SizedBox(height: 24),

                // Recent Activity timeline
                _buildRecentActivitySection(context, activeAgent),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hero Card Identity
  Widget _buildHeroCard(BuildContext context, DatabaseService db, Agent agent) {
    return CustomBentoCard(
      padding: 24,
      backgroundDecoration: Positioned(
        top: -40,
        right: -40,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 3),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(agent.avatarUrl),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.badgeCheck,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Agent ID: #${agent.id.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      agent.isOnline ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: agent.isOnline
                            ? AppTheme.primary
                            : AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      width: 48,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Switch(
                          value: agent.isOnline,
                          activeColor: AppTheme.primary,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppTheme.outlineVariant,
                          onChanged: (val) async {
                            try {
                              await db.toggleAgentOnlineStatus(agent.id, val);
                              if (context.mounted) {
                                CustomFeedback.showToast(
                                  context,
                                  'Agent status updated successfully',
                                  type: 'success',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                CustomFeedback.showToast(
                                  context,
                                  'Failed to update agent status: ${e.toString().replaceAll('Exception: ', '')}',
                                  type: 'error',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: IconButton(
              icon: const Icon(
                LucideIcons.phone,
                color: AppTheme.primary,
                size: 20,
              ),
              onPressed: () async {
                final phone = agent.phone.trim();
                if (phone.isEmpty) {
                  CustomFeedback.showToast(
                    context,
                    'Phone number not available for ${agent.name}',
                    type: 'warning',
                  );
                  return;
                }

                final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                try {
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  } else {
                    if (context.mounted) {
                      CustomFeedback.showToast(
                        context,
                        'Could not launch dialer for $phone',
                        type: 'error',
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    CustomFeedback.showToast(
                      context,
                      'Error placing call: ${e.toString()}',
                      type: 'error',
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bento Statistics Grid
  Widget _buildStatsBentoGrid(
    BuildContext context,
    Agent agent,
    double targetPercentage,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        final double cardWidth = (boxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Total Collected Box
            SizedBox(
              width: cardWidth,
              child: CustomBentoCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL COLLECTED',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${agent.collectedAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.trendingUp,
                          color: Colors.green,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '+12% this month',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recovery Rate Box
            SizedBox(
              width: cardWidth,
              child: CustomBentoCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECOVERY RATE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(targetPercentage * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: targetPercentage > 1.0 ? 1.0 : targetPercentage,
                        minHeight: 4,
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Active Cases Box (Wide on mobile)
            SizedBox(
              width: boxWidth,
              child: CustomBentoCard(
                padding: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACTIVE PORTFOLIO CASES',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${agent.casesCount}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '4 PRIORITY ACCOUNTS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Performance details card
  Widget _buildPerformanceDetails(BuildContext context, Agent agent) {
    return CustomBentoCard(
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surfaceContainerLow.withOpacity(0.5),
            child: const Text(
              'Performance Metadata',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.outlineVariant),
          _buildDetailRow(
            LucideIcons.mapPin,
            'Regional Assignment',
            agent.zone,
          ),
          const Divider(height: 1, color: AppTheme.outlineVariant),
          _buildDetailRow(LucideIcons.refreshCw, 'Last Sync Time', '5m ago'),
          const Divider(height: 1, color: AppTheme.outlineVariant),
          _buildDetailRow(LucideIcons.calendar, 'Join Date', 'Oct 12, 2022'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.outline),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Buttons Row
  Widget _buildQuickActionsRow(
    BuildContext context,
    DatabaseService db,
    Agent agent,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showEditDetailsDialog(context, db, agent),
            icon: const Icon(LucideIcons.userPen, size: 16),
            label: const Text(
              'Edit Agent Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPermissionsScreen(agent: agent),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.squarePen, size: 16),
                  label: const Text(
                    'Permissions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showDeactivationDialog(context, db, agent),
                  icon: const Icon(
                    LucideIcons.userX,
                    size: 16,
                    color: AppTheme.error,
                  ),
                  label: const Text(
                    'Deactivate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Deactivation confirmation modal dialog
  void _showDeactivationDialog(
    BuildContext context,
    DatabaseService db,
    Agent agent,
  ) {
    CustomFeedback.showFeedbackDialog(
      context,
      title: 'Deactivate Agent Profile?',
      message: 'This action will mark ${agent.name} (#${agent.id.toUpperCase()}) as inactive. They will no longer be able to log in or sync local collection ledgers until reactivated.',
      type: 'warning',
      confirmLabel: 'DEACTIVATE',
      onConfirm: () async {
        try {
          await db.toggleAgentOnlineStatus(agent.id, false);
          if (context.mounted) {
            CustomFeedback.showToast(
              context,
              'Agent ${agent.name} is now Offline.',
              type: 'success',
            );
          }
        } catch (e) {
          if (context.mounted) {
            CustomFeedback.showToast(
              context,
              'Failed to deactivate agent: ${e.toString().replaceAll('Exception: ', '')}',
              type: 'error',
            );
          }
        }
      },
    );
  }

  // Edit details form dialog
  void _showEditDetailsDialog(
    BuildContext context,
    DatabaseService db,
    Agent agent,
  ) {
    final nameController = TextEditingController(text: agent.name);
    final emailController = TextEditingController(text: agent.email);
    final phoneController = TextEditingController(text: agent.phone);

    CustomFeedback.showFeedbackDialog(
      context,
      title: 'Edit Agent Details',
      message: '',
      type: 'info',
      confirmLabel: 'SAVE CHANGES',
      onConfirm: () async {
        final newName = nameController.text.trim();
        final newEmail = emailController.text.trim();
        final newPhone = phoneController.text.trim();

        if (newName.isEmpty || newEmail.isEmpty || newPhone.isEmpty) {
          CustomFeedback.showToast(
            context,
            'All fields are required.',
            type: 'error',
          );
          return;
        }

        try {
          await db.updateAgentOnBackend(
            agentId: agent.id,
            fullName: newName,
            email: newEmail,
            mobile: newPhone,
          );
          if (context.mounted) {
            CustomFeedback.showToast(
              context,
              'Agent details updated successfully!',
              type: 'success',
            );
          }
        } catch (e) {
          if (context.mounted) {
            CustomFeedback.showToast(
              context,
              'Failed to update agent: ${e.toString().replaceAll('Exception: ', '')}',
              type: 'error',
            );
          }
        }
      },
      customBody: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter agent full name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter agent email address',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              hintText: 'Enter agent mobile number',
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // Timeline list for recent activities
  Widget _buildRecentActivitySection(BuildContext context, Agent agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Hardcoded activities based on the target agent or generic specs
        _buildActivityRow(
          LucideIcons.banknote,
          Colors.green.shade100,
          Colors.green.shade700,
          'Collection Recorded',
          '2h ago',
          'Collected ₹1,200 from Case #4412 (${agent.name.split(' ').last})',
        ),
        const SizedBox(height: 12),
        _buildActivityRow(
          LucideIcons.fileText,
          Colors.blue.shade100,
          Colors.blue.shade700,
          'Case Updated',
          '5h ago',
          'Changed status to \'PTP\' for Account #8892',
        ),
        const SizedBox(height: 12),
        _buildActivityRow(
          LucideIcons.mapPin,
          Colors.orange.shade100,
          Colors.orange.shade700,
          'Field Visit Logged',
          'Yesterday',
          'Attempted visit at \'North Mall Complex\'',
        ),
      ],
    );
  }

  Widget _buildActivityRow(
    IconData icon,
    Color bg,
    Color color,
    String title,
    String time,
    String desc,
  ) {
    return CustomBentoCard(
      padding: 16,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      time.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: AppTheme.outline,
          ),
        ],
      ),
    );
  }
}
