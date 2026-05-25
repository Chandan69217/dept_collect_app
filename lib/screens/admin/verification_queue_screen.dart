import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';

class VerificationQueueScreen extends StatelessWidget {
  final bool isEmbedded;

  const VerificationQueueScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return ListenableBuilder(
      listenable: db,
      builder: (context, child) {
        // Filter pending records
        final pendingPayments = db.payments.where((p) => p.status == 'PENDING').toList();

        final content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PENDING COLLECTION APPROVALS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                ),
              ),
            ),
            Expanded(
              child: pendingPayments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 64,
                            color: AppTheme.success.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Queue Clear!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All field collections have been verified.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: pendingPayments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = pendingPayments[index];

                        return CustomBentoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.pending_actions, color: AppTheme.warning, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.customerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          'Collected by: ${item.agentName} (${item.agentId.toUpperCase()})',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${item.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Method / Ref Identifier', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.paymentMethod} - ${item.transactionReference}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Capture Timestamp', style: TextStyle(fontSize: 10, color: AppTheme.secondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} - ${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.onSurface),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Capture file mock indicator
                              if (item.receiptImagePath != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.attachment, color: AppTheme.success, size: 14),
                                      SizedBox(width: 8),
                                      Text(
                                        'Receipt Photo attachment verified',
                                        style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Accept / Reject buttons row
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.success,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          db.approvePayment(item.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: AppTheme.success,
                                              content: Text(
                                                'Collection of ₹${item.amount.toStringAsFixed(2)} for ${item.customerName} approved successfully!',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.error,
                                          side: const BorderSide(color: AppTheme.error),
                                        ),
                                        onPressed: () {
                                          db.rejectPayment(item.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: AppTheme.error,
                                              content: Text(
                                                'Collection of ₹${item.amount.toStringAsFixed(2)} rejected.',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );

        if (isEmbedded) return content;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Verification Approvals'),
          ),
          body: content,
        );
      },
    );
  }
}
