import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../constants/api_constants.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../models/payment_record.dart';
import '../../models/customer.dart';
import '../agent/customer_details_screen.dart';
import '../../widgets/custom_feedback.dart';

class VerificationQueueScreen extends StatefulWidget {
  final bool isEmbedded;

  const VerificationQueueScreen({super.key, this.isEmbedded = false});

  @override
  State<VerificationQueueScreen> createState() => _VerificationQueueScreenState();
}

class _VerificationQueueScreenState extends State<VerificationQueueScreen> {
  bool _isLoading = true;
  final db = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Fetch latest assignments and recent uploads on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await db.fetchRecentUploads();
      } catch (e) {
        if (mounted) {
          _showSnackBar(context, 'Failed to load assignments: $e', false);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
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
        // Filter pending records
        final pendingPayments = db.payments
            .where((p) => p.status == 'Pending')
            .toList();

        // Calculate dynamic values for the stats bar directly from database service
        final String approvedTodayText =
            '₹${db.approvedTodaySum.toStringAsFixed(0)}';
        final String rejectedCountText = db.rejectedCount
            .toString()
            .padLeft(2, '0');

        final content = RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _isLoading = true;
            });
            try {
              await db.fetchRecentUploads();
            } catch (e) {
              if (context.mounted) {
                _showSnackBar(context, 'Failed to refresh: $e', false);
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
          color: AppTheme.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
            children: [
              if (_isLoading) CustomFeedback.showProgressIndicator(),
              // Sub Header Section
              _buildSubHeader(context, pendingPayments.length),
              const SizedBox(height: 16),

              // Stats Counter Bar
              _buildStatsBar(context, approvedTodayText, rejectedCountText),
              const SizedBox(height: 20),

              // Queue List / Empty State
              if (pendingPayments.isEmpty)
                _buildEmptyState(context)
              else
                ...pendingPayments.map(
                  (item) => _buildSwipeableCard(context, db, item),
                ),

              const SizedBox(height: 16),

              // Footer
              _buildLoadMoreFooter(context, pendingPayments.length),
            ],
          ),
        );

        if (widget.isEmbedded) return content;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('Verification Approvals')),
          body: content,
        );
      },
    );
  }

  // Sub Header widget
  Widget _buildSubHeader(BuildContext context, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUEUE MANAGEMENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Verification Queue',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.clipboardList,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count Pending',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Stats bar with approved today and rejected
  Widget _buildStatsBar(
    BuildContext context,
    String approvedSum,
    String rejectedCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.circleCheck,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Approved Today',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        approvedSum,
                        style: const TextStyle(
                          fontSize: 16,
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.flag,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejected',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rejectedCount,
                        style: const TextStyle(
                          fontSize: 16,
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
    );
  }

  // Dotted / Swipe backdrop block helper
  Widget _buildSwipeBackground({required bool isLeftToRight}) {
    return Container(
      alignment: isLeftToRight ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isLeftToRight ? Colors.green.shade600 : Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeftToRight
            ? [
                const Icon(
                  LucideIcons.circleCheck,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'APPROVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ]
            : [
                const Text(
                  'REJECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.circleX, color: Colors.white, size: 28),
              ],
      ),
    );
  }

  Widget _buildSwipeableCard(
    BuildContext context,
    DatabaseService db,
    PaymentRecord item,
  ) {
    final isUpi = item.paymentMethod.toUpperCase() == 'UPI';
    final imageUrl = (item.receiptImagePath != null && item.receiptImagePath!.isNotEmpty)
        ? (item.receiptImagePath!.startsWith('http')
            ? item.receiptImagePath!
            : '${ApiConstants.baseUrl}/uploads/${item.receiptImagePath}')
        : (isUpi
            ? 'https://lh3.googleusercontent.com/aida-public/AB6AXuDT0arBz1RsJ08eAQeEKV6dRpZdfTMevJEHBz8A1GKnuUhwVKNbKn41KAXP1i5wZnK_UIsrz07UJerqK-7JR0DrGhA97wm-p9fhObsdGAnNJUknc6euG0hwKb4O2lCJDmm6INB84Ng9K2nXidqk01oEbX3n1BYU8082z8EKOMqs50iEN8KM85tzaGG_GZCWS0v3Cc7KFrbSvj0fMCphfPqsu-yo3FGER52ftFAM9nIoEwLbyzDIbdiUSnQbOt3n0mFabvxyG-B3r3il'
            : 'https://lh3.googleusercontent.com/aida-public/AB6AXuCtQhJG7cGf6cEF0RaYY8O_qVk-mU1DPXP7y1XRlIun8UsamoMnakKqUhsGJjR6FMZ4alkW2fdPbPXjNY9D9dZBlIUN1Sr6Nt1S29kGODHve5nlGWnlXixlWrKb6ox5cxnaUkv4PQKR60yJpQFIGH2CXl9QgLTS3GtkfkWs8NpsjzUld67dlOiYrvTwKJARRZ2lQ5MZlx5tJ5hdGduGfuVQd_ag5h1uom-W01GITQ2JmXiXGSIKIWzBrthpC-ERcBm_WTttcLUU9zU-');

    final comment = item.transactionReference.isNotEmpty
        ? item.transactionReference
        : (isUpi
            ? 'Payment confirmed via transaction ID ${item.transactionReference}. Customer was satisfied.'
            : 'Full settlement for invoice #${item.transactionReference}. Counted and verified twice.');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Dismissible(
        key: Key(item.id),
        background: _buildSwipeBackground(isLeftToRight: true),
        secondaryBackground: _buildSwipeBackground(isLeftToRight: false),
        confirmDismiss: (direction) async {
          final localContext = context;
          setState(() {
            _isLoading = true;
          });
          try {
            if (direction == DismissDirection.startToEnd) {
              // Swipe Right -> Approve
              await db.approvePayment(item.id);
              if (localContext.mounted) {
                _showSnackBar(
                  localContext,
                  'Collection of ₹${item.amount.toStringAsFixed(0)} for ${item.customerName} approved successfully!',
                  true,
                );
              }
              return true;
            } else {
              // Swipe Left -> Reject
              await db.rejectPayment(item.id);
              if (localContext.mounted) {
                _showSnackBar(
                  localContext,
                  'Collection of ₹${item.amount.toStringAsFixed(0)} rejected.',
                  false,
                );
              }
              return true;
            }
          } catch (e) {
            if (localContext.mounted) {
              _showSnackBar(
                localContext,
                'Failed to update collection status: ${e.toString().replaceAll('Exception: ', '')}',
                false,
              );
            }
            return false;
          } finally {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        },
        child: CustomBentoCard(
          padding: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        child: Text(
                          _getAgentInitials(item.agentName),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.agentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Agent ID: #${item.agentId.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isUpi
                              ? AppTheme.surfaceContainerHigh
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.paymentMethod.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isUpi
                                ? AppTheme.primary
                                : Colors.orange.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dashed Divider Line
              const DashedDivider(height: 1, dashWidth: 5, dashGap: 3),
              const SizedBox(height: 12),

              // Customer / Date Metadata Column Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      final customerList = db.customers.where((c) => c.id == item.customerId);
                      final Customer? customer = customerList.isNotEmpty ? customerList.first : null;
                      if (customer != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetailsScreen(customer: customer),
                          ),
                        );
                      } else {
                        CustomFeedback.showToast(
                          context,
                          'Customer details not found for ${item.customerName}',
                          type: 'error',
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CUSTOMER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.info,
                              size: 13,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'DATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(item.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Receipt Image & Comment Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () =>
                        _showReceiptModal(context, item, imageUrl, comment),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 64,
                                  height: 64,
                                  color: AppTheme.surfaceContainerHigh,
                                  child: const Icon(
                                    LucideIcons.unlink,
                                    size: 24,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                          ),
                          Container(
                            width: 64,
                            height: 64,
                            color: Colors.black.withOpacity(0.2),
                          ),
                          Icon(
                            isUpi ? LucideIcons.eye : LucideIcons.camera,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '"$comment"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () async {
                          final localContext = context;
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await db.approvePayment(item.id);
                            if (localContext.mounted) {
                              _showSnackBar(
                                localContext,
                                'Collection of ₹${item.amount.toStringAsFixed(0)} for ${item.customerName} approved successfully!',
                                true,
                              );
                            }
                          } catch (e) {
                            if (localContext.mounted) {
                              _showSnackBar(
                                localContext,
                                'Failed to approve collection: ${e.toString().replaceAll('Exception: ', '')}',
                                false,
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        icon: const Icon(LucideIcons.check, size: 16),
                        label: const Text(
                          'Approve',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                        onPressed: _isLoading ? null : () async {
                          final localContext = context;
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await db.rejectPayment(item.id);
                            if (localContext.mounted) {
                              _showSnackBar(
                                localContext,
                                'Collection of ₹${item.amount.toStringAsFixed(0)} rejected.',
                                false,
                              );
                            }
                          } catch (e) {
                            if (localContext.mounted) {
                              _showSnackBar(
                                localContext,
                                'Failed to reject collection: ${e.toString().replaceAll('Exception: ', '')}',
                                false,
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  // Interactive Receipt Modal Popup with Checklist verification flow
  void _showReceiptModal(
    BuildContext context,
    PaymentRecord item,
    String imageUrl,
    String comment,
  ) {
    // Internal checklist state variables declared here to persist between dialog rebuilds
    bool checkTxn = false;
    bool checkName = false;
    bool checkAmt = false;
    bool checkSign = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Receipt',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: AppTheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Verification Checklist',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              color: AppTheme.secondary,
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Large Zoomable Image frame
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              panEnabled: true,
                              minScale: 1.0,
                              maxScale: 3.0,
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: double.infinity,
                                      height: 240,
                                      color: AppTheme.surfaceContainerHigh,
                                      child: const Icon(
                                        LucideIcons.unlink,
                                        size: 48,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      LucideIcons.zoomIn,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Pinch to Zoom',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"$comment"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const DashedDivider(height: 1),
                      const SizedBox(height: 16),
                      const Text(
                        'REQUIRED CHECKS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // List of Checklist items
                      _buildCheckItem(
                        'Reference Matches: ${item.transactionReference}',
                        checkTxn,
                        (val) => setDialogState(() => checkTxn = val ?? false),
                      ),
                      _buildCheckItem(
                        'Payer Name Matches: ${item.customerName}',
                        checkName,
                        (val) => setDialogState(() => checkName = val ?? false),
                      ),
                      _buildCheckItem(
                        'Amount Matches: ₹${item.amount.toStringAsFixed(0)}',
                        checkAmt,
                        (val) => setDialogState(() => checkAmt = val ?? false),
                      ),
                      _buildCheckItem(
                        'Stamp & Official Signature Present',
                        checkSign,
                        (val) => setDialogState(() => checkSign = val ?? false),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  (checkTxn &&
                                      checkName &&
                                      checkAmt &&
                                      checkSign &&
                                      !_isLoading)
                                  ? () async {
                                      final parentContext = context;
                                      Navigator.pop(dialogContext);
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      try {
                                        await db.approvePayment(item.id);
                                        if (parentContext.mounted) {
                                          _showSnackBar(
                                            parentContext,
                                            'Collection of ₹${item.amount.toStringAsFixed(0)} for ${item.customerName} approved successfully!',
                                            true,
                                          );
                                        }
                                      } catch (e) {
                                        if (parentContext.mounted) {
                                          _showSnackBar(
                                            parentContext,
                                            'Failed to approve collection: ${e.toString().replaceAll('Exception: ', '')}',
                                            false,
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                disabledBackgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.grey.shade500,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'APPROVE COLLECTION',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  // Checklist Item Widget Builder
  Widget _buildCheckItem(
    String title,
    bool val,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      value: val,
      onChanged: onChanged,
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      activeColor: Colors.green.shade700,
    );
  }

  // Load More & Bottom stats footer
  Widget _buildLoadMoreFooter(BuildContext context, int count) {
    if (count == 0) return const SizedBox();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.history,
              color: AppTheme.secondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Showing ${count > 2 ? 2 : count} of $count pending requests',
              style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _showSnackBar(context, 'All pending requests loaded.', true);
          },
          child: const Text(
            'LOAD MORE',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Empty Queue View
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.badgeCheck,
              size: 64,
              color: Colors.green.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Queue Clear!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All field collections have been verified.',
              style: TextStyle(fontSize: 14, color: AppTheme.secondary),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for agent avatar initials extraction
  String _getAgentInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      if (parts[0].toLowerCase() == 'agent') {
        return 'A${parts[1][0].toUpperCase()}';
      }
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }

  // Custom float SnackBar helper
  void _showSnackBar(BuildContext context, String message, bool isSuccess) {
    CustomFeedback.showToast(
      context,
      message,
      type: isSuccess ? 'success' : 'error',
    );
  }
}

// Custom painter / dashed divider line implementation
class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashGap;

  const DashedDivider({
    super.key,
    this.height = 1.0,
    this.color = AppTheme.outlineVariant,
    this.dashWidth = 5.0,
    this.dashGap = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashGap)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}

