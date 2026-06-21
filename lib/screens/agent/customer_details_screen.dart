import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_bento_card.dart';
import 'record_payment_sheet.dart';
import 'schedule_visit_sheet.dart';
import '../../widgets/custom_feedback.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final dynamic customer; // Customer model

  const CustomerDetailsScreen({super.key, required this.customer});

  String _formatCurrency(double amount) {
    if (!_hasPermission('amountDue')) {
      return '••••';
    }
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  bool _hasPermission(String fieldKey) {
    final user = DatabaseService().currentUser;
    if (user != null && !user.isAdmin) {
      return user.permissions[fieldKey] ?? true;
    }
    return true;
  }

  String _getMaskedText(String fieldKey, String value) {
    if (!_hasPermission(fieldKey)) {
      return '••••••••';
    }
    return value;
  }

  Widget _buildAssetRow({
    required String label,
    required String value,
    bool isMasked = false,
    String? fieldName,
  }) {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.secondary)),
              Text(
                isMasked && fieldName != null
                    ? _getMaskedText(fieldName, value)
                    : value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return ListenableBuilder(
      listenable: db,
      builder: (context, child) {
        // Re-fetch current state of the customer
        final currentCust = db.customers.firstWhere(
          (c) => c.id == customer.id,
          orElse: () => customer,
        );

        final bool isAdmin = db.currentRole == AppConstants.roleAdmin;

        final bool isPaid =
            currentCust.status == AppConstants.statusPaid ||
            currentCust.status == AppConstants.statusClosed;
        final bool isPending =
            currentCust.status == AppConstants.statusPendingVerification;

        // Extract initials for the avatar
        final initials = currentCust.name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppTheme.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (!isAdmin && _hasPermission('deleteRecords'))
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppTheme.error),
                  tooltip: 'Remove Assignment',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Assignment'),
                        content: const Text(
                          'Are you sure you want to remove this assignment from your queue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              try {
                                await db.unassignCase(currentCust.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Assignment removed successfully.',
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to remove assignment: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Remove',
                              style: TextStyle(color: AppTheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryContainer,
                      child: Text(
                        initials.length > 2
                            ? initials.substring(0, 2)
                            : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Scrollable Details Body
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, isAdmin ? 16 : 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Customer Hero Section
                    CustomBentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // High Priority Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            currentCust.priority ==
                                                AppConstants.priorityHigh
                                            ? AppTheme.errorContainer
                                            : AppTheme.warningContainer,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.alertTriangle,
                                            size: 12,
                                            color:
                                                currentCust.priority ==
                                                    AppConstants.priorityHigh
                                                ? AppTheme.error
                                                : AppTheme.warning,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            !_hasPermission('priority')
                                                ? '•••• Priority'
                                                : '${currentCust.priority == AppConstants.priorityHigh ? 'High' : 'Medium'} Priority',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  currentCust.priority ==
                                                      AppConstants.priorityHigh
                                                  ? AppTheme.error
                                                  : AppTheme.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getMaskedText('name', currentCust.name),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 28,
                                            letterSpacing: -0.5,
                                            color: AppTheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getMaskedText("name", currentCust.name),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.secondary),
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    AppTheme.surfaceContainerHighest,
                                child: const Icon(
                                  LucideIcons.user,
                                  color: AppTheme.primary,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Phone and WhatsApp Actions Row
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (!_hasPermission('phone')) {
                                        CustomFeedback.showToast(
                                          context,
                                          'Calling permission denied.',
                                          type: 'warning',
                                        );
                                        return;
                                      }
                                      final phone = currentCust.phone.trim();
                                      if (phone.isEmpty) {
                                        CustomFeedback.showToast(
                                          context,
                                          'Phone number not available for ${_getMaskedText('name', currentCust.name)}',
                                          type: 'warning',
                                        );
                                        return;
                                      }

                                      final Uri phoneUri = Uri(
                                        scheme: 'tel',
                                        path: phone,
                                      );
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
                                    icon: const Icon(
                                      LucideIcons.phone,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Call',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(
                                        color: AppTheme.outline,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (!_hasPermission('phone')) {
                                        CustomFeedback.showToast(
                                          context,
                                          'Phone/WhatsApp permission denied.',
                                          type: 'warning',
                                        );
                                        return;
                                      }
                                      final phone = currentCust.phone
                                          .trim()
                                          .replaceAll(RegExp(r'\D'), '');
                                      if (phone.isEmpty) {
                                        CustomFeedback.showToast(
                                          context,
                                          'Phone number not available.',
                                          type: 'warning',
                                        );
                                        return;
                                      }
                                      String cleanPhone = phone;
                                      if (phone.length == 10) {
                                        cleanPhone = '91$phone';
                                      }
                                      final url = Uri.parse(
                                        'https://wa.me/$cleanPhone',
                                      );
                                      try {
                                        final launched = await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched) {
                                          await launchUrl(
                                            url,
                                            mode: LaunchMode.platformDefault,
                                          );
                                        }
                                      } catch (e) {
                                        try {
                                          await launchUrl(
                                            url,
                                            mode: LaunchMode.platformDefault,
                                          );
                                        } catch (e2) {
                                          if (context.mounted) {
                                            CustomFeedback.showToast(
                                              context,
                                              'Could not launch WhatsApp: $e2',
                                              type: 'error',
                                            );
                                          }
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      LucideIcons.messageCircle,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'WhatsApp',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Financial Overview Bento Grid
                    Column(
                      children: [
                        // Pending EMI (Wide Card)
                        CustomBentoCard(
                          backgroundColor: isPaid
                              ? AppTheme.success
                              : AppTheme.primaryContainer,
                          borderSide: BorderSide.none,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending EMI',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isPaid
                                        ? 'Fully Paid'
                                        : _formatCurrency(
                                            currentCust.amountDue,
                                          ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Due Date',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        _getMaskedText(
                                          "overdueDays",
                                          AppConstants.dateFormat
                                              .format(currentCust.dueDate)
                                              .split(',')
                                              .first,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Total Loan & Status (Side by Side)
                        Row(
                          children: [
                            Expanded(
                              child: CustomBentoCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Loan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.secondary,
                                            fontSize: 10,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      !_hasPermission('amountDue')
                                          ? '••••'
                                          : _formatCurrency(
                                              currentCust.amountDue,
                                            ),
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomBentoCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Collection Status',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.secondary,
                                            fontSize: 10,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isPaid
                                          ? 'Paid'
                                          : (isPending ? 'Pending' : 'Overdue'),
                                      style: TextStyle(
                                        color: isPaid
                                            ? AppTheme.success
                                            : (isPending
                                                  ? AppTheme.warning
                                                  : AppTheme.error),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
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
                    const SizedBox(height: 16),

                    // 3. Asset Information Card
                    CustomBentoCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.car,
                                color: AppTheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Asset Information',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppTheme.onSurface),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildAssetRow(
                            label: "Model",
                            value: currentCust.assetModel,
                            isMasked: true,
                            fieldName: 'assetModel',
                          ),

                          _buildAssetRow(
                            label: "Reg No.",
                            value: currentCust.assetRegNo,
                            isMasked: true,
                            fieldName: 'assetRegNo',
                          ),

                          _buildAssetRow(
                            label: "Variant",
                            value: currentCust.assetVariant,
                            isMasked: true,
                            fieldName: 'assetVariant',
                          ),

                          _buildAssetRow(
                            label: "Engine No.",
                            value: currentCust.engineNumber,
                            isMasked: true,
                            fieldName: 'engineNumber',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Address Section
                    CustomBentoCard(
                      padding: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.mapPin,
                                      color: AppTheme.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Home Address',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: AppTheme.onSurface),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _getMaskedText(
                                    'address',
                                    currentCust.address,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Vector Map Custom Painted Road Mockup
                          Container(
                            height: 128,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(AppTheme.radiusLarge),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(painter: _MapPainter()),
                                ),
                                // Pulser dot on target location
                                const Positioned(
                                  right: 80,
                                  top: 45,
                                  child: _PulseMarker(),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primary,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        side: const BorderSide(
                                          color: AppTheme.outlineVariant,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (!_hasPermission('address')) {
                                        CustomFeedback.showToast(
                                          context,
                                          'Address access denied.',
                                          type: 'warning',
                                        );
                                        return;
                                      }
                                      final address = _getMaskedText(
                                        "address",
                                        currentCust.address,
                                      );
                                      final url = Uri.parse(
                                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
                                      );
                                      try {
                                        final launched = await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched) {
                                          await launchUrl(
                                            url,
                                            mode: LaunchMode.platformDefault,
                                          );
                                        }
                                      } catch (e) {
                                        try {
                                          await launchUrl(
                                            url,
                                            mode: LaunchMode.platformDefault,
                                          );
                                        } catch (e2) {
                                          if (context.mounted) {
                                            CustomFeedback.showToast(
                                              context,
                                              'Could not launch maps: $e2',
                                              type: 'error',
                                            );
                                          }
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      LucideIcons.navigation,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Navigate',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Notes History Log
                    if (_hasPermission('accessHistory')) ...[
                      CustomBentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VISIT FEEDBACK HISTORY',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (currentCust.notes.isEmpty)
                              const Text(
                                'No comments logged for this case yet.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: currentCust.notes.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '• ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            currentCust.notes[index],
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Sticky Contextual Actions Footer Bar
              if (!isAdmin)
                Positioned(
                  bottom: 0,
                  left: 0,
                  width: MediaQuery.of(context).size.width,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      12 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Row(
                      children: [
                        // Record Collection
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPaid
                                    ? AppTheme.success
                                    : (isPending
                                          ? AppTheme.warning
                                          : AppTheme.primary),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLarge,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                if (isPaid) return;
                                if (!_hasPermission('approvePartial')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You do not have permission to collect payments.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      RecordPaymentSheet(customer: currentCust),
                                );
                              },
                              icon: Icon(
                                isPaid
                                    ? LucideIcons.circleCheck
                                    : LucideIcons.banknote,
                              ),
                              label: Text(
                                isPaid
                                    ? 'EMI Settled'
                                    : (isPending
                                          ? 'Approval Processing...'
                                          : 'Record Collection'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Schedule calendar
                        SizedBox(
                          width: 56,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.background,
                              side: const BorderSide(
                                color: AppTheme.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLarge,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              if (!_hasPermission('editDetails')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You do not have permission to schedule follow-up visits.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    ScheduleVisitSheet(customer: currentCust),
                              );
                            },
                            child: const Icon(LucideIcons.calendarClock),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = AppTheme.primaryContainer.withOpacity(0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routeSolidPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw main roads
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.1,
        size.width * 0.8,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height * 0.75);

    final path2 = Path()
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.9, size.height * 0.2);

    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, roadPaint);

    // Active route paths
    final activeRoute = Path()
      ..moveTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.41, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.4,
        size.width * 0.68,
        size.height * 0.45,
      )
      ..lineTo(size.width * 0.8, size.height * 0.36);

    canvas.drawPath(activeRoute, routePaint);
    canvas.drawPath(activeRoute, routeSolidPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const Icon(LucideIcons.mapPin, color: AppTheme.primary, size: 24),
          ],
        );
      },
    );
  }
}
