import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';

class CustomFeedback {
  static void showToast(BuildContext context, String message, {String type = 'info'}) {
    IconData icon;
    Color color;
    Color bg;

    switch (type) {
      case 'success':
        icon = LucideIcons.circleCheck;
        color = const Color(0xFF1B5E20);
        bg = const Color(0xFFE8F5E9);
        break;
      case 'error':
        icon = LucideIcons.circleAlert;
        color = const Color(0xFFBA1A1A);
        bg = const Color(0xFFFFDAD6);
        break;
      case 'warning':
        icon = LucideIcons.triangleAlert;
        color = const Color(0xFFE65100);
        bg = const Color(0xFFFFF3E0);
        break;
      default:
        icon = LucideIcons.info;
        color = AppTheme.primary;
        bg = AppTheme.surfaceContainerLow;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 2),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showFeedbackDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String type,
    String confirmLabel = 'CONFIRM',
    String cancelLabel = 'CANCEL',
    VoidCallback? onConfirm,
    bool showCancel = true,
    Widget? customBody,
  }) {
    IconData icon;
    Color color;
    Color bg;

    switch (type) {
      case 'success':
        icon = LucideIcons.circleCheck;
        color = const Color(0xFF1B5E20);
        bg = const Color(0xFFE8F5E9);
        break;
      case 'error':
        icon = LucideIcons.shieldAlert;
        color = const Color(0xFFBA1A1A);
        bg = const Color(0xFFFFDAD6);
        break;
      case 'warning':
        icon = LucideIcons.triangleAlert;
        color = const Color(0xFFE65100);
        bg = const Color(0xFFFFF3E0);
        break;
      default:
        icon = LucideIcons.info;
        color = AppTheme.primary;
        bg = AppTheme.surfaceContainerLow;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing circular icon header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (customBody != null)
              customBody
            else
              Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (showCancel)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(cancelLabel),
                    ),
                  ),
                if (showCancel) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (onConfirm != null) onConfirm();
                    },
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
