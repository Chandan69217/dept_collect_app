import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import 'schedule_visit_sheet.dart';
import '../../widgets/custom_feedback.dart';

class RecordPaymentSheet extends StatefulWidget {
  final dynamic customer;

  const RecordPaymentSheet({
    super.key,
    required this.customer,
  });

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _refController = TextEditingController();
  final _db = DatabaseService();
  String _paymentMethod = 'UPI'; // 'Cash', 'UPI', 'Cheque'
  bool _receiptUploaded = false;

  @override
  void initState() {
    super.initState();
    // Default prefill amount
    _amountController.text = widget.customer.amountDue.toStringAsFixed(2);
    _updateReference();
  }

  void _updateReference() {
    final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    setState(() {
      if (_paymentMethod == 'UPI') {
        _refController.text = 'UPI$rand';
      } else if (_paymentMethod == 'Cheque') {
        _refController.text = 'CHQ$rand';
      } else {
        _refController.text = 'CASH$rand';
      }
    });
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String _formatDate(DateTime date, String customerId) {
    if (customerId == 'cust_robert') {
      return '12 Oct 2023';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _handleSubmit() {
    final amt = double.tryParse(_amountController.text) ?? 0;
    if (amt <= 0) {
      CustomFeedback.showToast(
        context,
        'Please enter a valid payment amount.',
        type: 'error',
      );
      return;
    }

    // Record payment
    _db.recordPayment(
      customerId: widget.customer.id,
      amount: amt,
      method: _paymentMethod,
      reference: _refController.text,
      receiptPath: _receiptUploaded ? '/simulated/receipt_capture.jpg' : null,
    );

    Navigator.pop(context); // pop bottom sheet

    CustomFeedback.showToast(
      context,
      'Collection of ₹${amt.toStringAsFixed(0)} recorded for ${widget.customer.name}! Pending Admin Verification.',
      type: 'success',
    );
  }

  void _handleSchedule() {
    Navigator.pop(context); // close current sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleVisitSheet(customer: widget.customer),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardOffset = MediaQuery.of(context).viewInsets.bottom;
    final bool isPaid = widget.customer.status == 'PAID';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + keyboardOffset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Debtor Context Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: Border.all(color: AppTheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customer.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Account #8829-X-${widget.customer.id == 'cust_robert' ? '204' : '308'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : 'Overdue',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL OUTSTANDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(widget.customer.amountDue),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Due: ${_formatDate(widget.customer.dueDate, widget.customer.id)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Section Title
            Row(
              children: const [
                Icon(LucideIcons.banknote, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'RECORD COLLECTION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input Field
            const Text(
              'Amount Collected (INR)',
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: Border.all(color: AppTheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0.00',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Mode Grid Options
            const Text(
              'Payment Mode',
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildModeButton(
                  mode: 'Cash',
                  icon: LucideIcons.banknote,
                  isSelected: _paymentMethod == 'Cash',
                ),
                const SizedBox(width: 8),
                _buildModeButton(
                  mode: 'UPI',
                  icon: LucideIcons.qrCode,
                  isSelected: _paymentMethod == 'UPI',
                ),
                const SizedBox(width: 8),
                _buildModeButton(
                  mode: 'Cheque',
                  icon: LucideIcons.fileText,
                  isSelected: _paymentMethod == 'Cheque',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notes Observations TextArea
            const Text(
              'Notes / Observations',
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceContainerLowest,
                hintText: 'Record discussion details...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Receipt Capture Upload proof
            const Text(
              'Receipt / Proof of Payment',
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _receiptUploaded = !_receiptUploaded;
                });
                CustomFeedback.showToast(
                  context,
                  _receiptUploaded
                      ? 'Simulated Camera Capture: Receipt processed & attached!'
                      : 'Receipt document removed.',
                  type: _receiptUploaded ? 'success' : 'info',
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: _receiptUploaded ? AppTheme.success : AppTheme.outlineVariant,
                ),
                child: Container(
                  height: 96,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _receiptUploaded ? AppTheme.successContainer.withOpacity(0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _receiptUploaded ? LucideIcons.circleCheck : LucideIcons.camera,
                        color: _receiptUploaded ? AppTheme.success : AppTheme.secondary,
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _receiptUploaded ? 'RECEIPT ATTACHED' : 'TAP TO CAPTURE RECEIPT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _receiptUploaded ? AppTheme.success : AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save and Schedule Action buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: _handleSubmit,
                icon: const Icon(LucideIcons.save, size: 18),
                label: const Text(
                  'SAVE COLLECTION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: _handleSchedule,
                icon: const Icon(LucideIcons.calendarClock, size: 18),
                label: const Text(
                  'SCHEDULE FOLLOW-UP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String mode,
    required IconData icon,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMethod = mode;
            _updateReference();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryContainer.withOpacity(0.1) : AppTheme.surfaceContainerLowest,
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.secondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                mode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double dashWidth = 8.0;
    final double dashSpace = 4.0;

    // Paint dashed rounded rectangle
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    double distance = 0.0;
    for (var metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
