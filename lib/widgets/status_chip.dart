import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final String type; // 'PAID', 'OVERDUE', 'PENDING_VERIFICATION', 'PENDING', 'HIGH', 'MEDIUM', 'LOW'

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type.toUpperCase()) {
      case 'PAID':
      case 'APPROVED':
      case 'COMPLETED':
      case 'CLOSED':
        bg = AppTheme.successContainer;
        fg = AppTheme.success;
        break;
      case 'OVERDUE':
      case 'HIGH':
      case 'REJECTED':
      case 'ASSIGNED':
        bg = AppTheme.errorContainer;
        fg = AppTheme.error;
        break;
      case 'PENDING_VERIFICATION':
      case 'PENDING':
      case 'MEDIUM':
      case 'IN PROGRESS':
        bg = AppTheme.warningContainer;
        fg = AppTheme.warning;
        break;
      case 'LOW':
        bg = AppTheme.surfaceContainerLow;
        fg = AppTheme.primary;
        break;
      default:
        bg = AppTheme.secondary.withOpacity(0.1);
        fg = AppTheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
