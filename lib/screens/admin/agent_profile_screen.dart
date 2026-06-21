import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../models/agent.dart';
import 'edit_permissions_screen.dart';
import '../../widgets/custom_feedback.dart';
import '../../config/field_mapping.dart';
import '../../constants/app_constants.dart';
import '../../models/customer.dart';
import '../../models/payment_record.dart';
import '../agent/customer_details_screen.dart';
import '../../widgets/status_chip.dart';

class AgentProfileScreen extends StatefulWidget {
  final Agent agent;

  const AgentProfileScreen({super.key, required this.agent});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  bool _isLoadingAssignments = true;
  final db = DatabaseService();
  int _activeTab = 0; // 0 for Portfolio Cases, 1 for Collection Records

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await db.fetchAgentAssignments(widget.agent.id);
      } catch (e) {
        debugPrint('Error loading assignments: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingAssignments = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, child) {
        // Find the most up-to-date agent details from shared state
        final activeAgent = db.agents.firstWhere(
          (a) => a.id == widget.agent.id,
          orElse: () => widget.agent,
        );

        final targetPercentage = activeAgent.assignedTarget == 0
            ? 0.88 // Fallback standard representation matching mockup
            : (activeAgent.collectedAmount / activeAgent.assignedTarget);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Agent Profile'),
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
                const SizedBox(height: 16),

                // Security & Permission Clearance
                _buildClearanceCard(context, activeAgent),
                const SizedBox(height: 20),

                // Quick Actions
                _buildQuickActionsRow(context, db, activeAgent),
                const SizedBox(height: 24),

                // Dynamic Portfolio / Collections tabbed section
                _buildDynamicTabsSection(context, activeAgent),
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
                        'CUSTOMER',
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
          _buildDetailRow(
            LucideIcons.refreshCw,
            'Last Sync Time',
            AppConstants.dateFormat.format(DateTime.now()),
          ),
          const Divider(height: 1, color: AppTheme.outlineVariant),
          _buildDetailRow(
            LucideIcons.calendar,
            'Join Date',
            AppConstants.dateFormat.format(agent.joinDate).split(",").first,
          ),
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
                        builder: (context) =>
                            EditPermissionsScreen(agent: agent),
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
      message:
          'This action will mark ${agent.name} (#${agent.id.toUpperCase()}) as inactive. They will no longer be able to log in or sync local collection ledgers until reactivated.',
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

  // Edit details form dialog in a modal bottom sheet
  void _showEditDetailsDialog(
    BuildContext context,
    DatabaseService db,
    Agent agent,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: agent.name);
    final emailController = TextEditingController(text: agent.email);
    final phoneController = TextEditingController(text: agent.phone);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Agent Details',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Update the agent\'s personal and contact information. These details will sync with the central server.',
                      style: TextStyle(fontSize: 13, color: AppTheme.secondary),
                    ),
                    const SizedBox(height: 24),

                    // Full Name Field
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      enabled: !isSaving,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter agent full name',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Full Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Address Field
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter agent email address',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!AppConstants.emailRegex.hasMatch(val.trim())) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mobile Number Field
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        counterText: "",
                        hintText: 'Enter 10-digit mobile number',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Mobile number is required';
                        }
                        if (!AppConstants.mobileRegex.hasMatch(val.trim())) {
                          return 'Invalid phone format (must be 10 digits)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  setModalState(() {
                                    isSaving = true;
                                  });

                                  final newName = nameController.text.trim();
                                  final newEmail = emailController.text.trim();
                                  final newPhone = phoneController.text.trim();

                                  try {
                                    await db.updateAgentOnBackend(
                                      agentId: agent.id,
                                      fullName: newName,
                                      email: newEmail,
                                      mobile: newPhone,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      CustomFeedback.showToast(
                                        context,
                                        'Agent details updated successfully!',
                                        type: 'success',
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() {
                                      isSaving = false;
                                    });
                                    if (context.mounted) {
                                      CustomFeedback.showToast(
                                        context,
                                        'Failed to update agent: ${e.toString().replaceAll('Exception: ', '')}',
                                        type: 'error',
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'SAVE CHANGES',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicTabsSection(BuildContext context, Agent activeAgent) {
    final myCustomers = db.customers
        .where((c) => c.assignedAgentId == activeAgent.id)
        .toList();
    final agentPayments = db.payments
        .where((p) => p.agentId == activeAgent.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildTabHeader(0, 'Assigned Portfolio', myCustomers.length),
            const SizedBox(width: 12),
            _buildTabHeader(1, 'Collections Log', agentPayments.length),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingAssignments)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CustomFeedback.showProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text(
                    'Loading assignments & history...',
                    style: TextStyle(color: AppTheme.secondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else if (_activeTab == 0) ...[
          if (myCustomers.isEmpty)
            _buildEmptyState(
              'No Assignments Found',
              'This agent has no active portfolio assignments.',
            )
          else
            ...myCustomers.map(
              (customer) => _buildAssignmentCard(context, customer),
            ),
        ] else ...[
          if (agentPayments.isEmpty)
            _buildEmptyState(
              'No Payments Found',
              'This agent has not logged any collections yet.',
            )
          else
            ...agentPayments.map(
              (payment) => _buildPaymentRecordCard(context, payment),
            ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.folderOpen,
            size: 48,
            color: AppTheme.secondary.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.secondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader(int index, String label, int count) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryContainer.withOpacity(0.08)
              : Colors.transparent,
          border: Border.all(
            color: isActive ? AppTheme.primary : Colors.transparent,
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary
                    : AppTheme.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Customer customer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CustomBentoCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailsScreen(customer: customer),
            ),
          );
        },
        padding: 16,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    customer.status.toLowerCase() == 'completed' ||
                        customer.status.toLowerCase() == 'closed'
                    ? Colors.green.shade50
                    : customer.status.toLowerCase() == 'rejected'
                    ? Colors.red.shade50
                    : AppTheme.primaryContainer.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                customer.status.toLowerCase() == 'completed' ||
                        customer.status.toLowerCase() == 'closed'
                    ? LucideIcons.checkCircle2
                    : customer.status.toLowerCase() == 'rejected'
                    ? LucideIcons.alertTriangle
                    : LucideIcons.banknote,
                color:
                    customer.status.toLowerCase() == 'completed' ||
                        customer.status.toLowerCase() == 'closed'
                    ? Colors.green.shade700
                    : customer.status.toLowerCase() == 'rejected'
                    ? Colors.red.shade700
                    : AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.address,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${customer.amountDue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                StatusChip(
                  label: customer.status.toUpperCase(),
                  type: customer.status.toUpperCase(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRecordCard(BuildContext context, PaymentRecord payment) {
    final isCompleted =
        payment.status.toLowerCase() == 'completed' ||
        payment.status.toLowerCase() == 'paid' ||
        payment.status.toLowerCase() == 'closed';
    final isRejected = payment.status.toLowerCase() == 'rejected';

    Color statusColor = AppTheme.primary;
    if (isCompleted) statusColor = Colors.green.shade700;
    if (isRejected) statusColor = Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CustomBentoCard(
        padding: 16,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.shade50
                    : isRejected
                    ? Colors.red.shade50
                    : AppTheme.primaryContainer.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? LucideIcons.checkCircle
                    : isRejected
                    ? LucideIcons.xCircle
                    : LucideIcons.clock,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          payment.paymentMethod.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.transactionReference.isNotEmpty
                              ? payment.transactionReference
                              : 'No remarks',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${payment.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade50
                        : isRejected
                        ? Colors.red.shade50
                        : AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearanceCard(BuildContext context, Agent agent) {
    return CustomBentoCard(
      padding: 16.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.shieldCheck, color: AppTheme.primary, size: 18),
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
            'The following data access and operational clearances are set for this agent account by system administrators:',
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
            'Approve Partial Payments',
            agent.permissions['approvePartial'] ?? false,
          ),
          _buildClearanceRow(
            'Remove Assign Records',
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
                      isGranted ? LucideIcons.check : LucideIcons.lock,
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
