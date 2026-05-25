import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_feedback.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return ListenableBuilder(
      listenable: db,
      builder: (context, child) {
        final unreadCount = db.notifications.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      db.markAllNotificationsAsRead();
                      CustomFeedback.showToast(
                        context,
                        'All notifications marked as read.',
                        type: 'success',
                      );
                    },
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text(
                      'MARK ALL READ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: db.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: AppTheme.secondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Notifications Yet',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verification statuses and case assignments will appear here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: db.notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = db.notifications[index];
                    IconData icon;
                    Color color;
                    Color bg;

                    switch (item.type) {
                      case 'approval':
                        icon = Icons.check_circle_outline;
                        color = AppTheme.success;
                        bg = AppTheme.successContainer;
                        break;
                      case 'assignment':
                        icon = Icons.assignment_outlined;
                        color = AppTheme.primary;
                        bg = AppTheme.primaryContainer.withOpacity(0.1);
                        break;
                      default:
                        icon = Icons.error_outline_rounded;
                        color = AppTheme.warning;
                        bg = AppTheme.warningContainer;
                    }

                    return Material(
                      color: item.isRead 
                          ? Colors.white 
                          : AppTheme.primaryContainer.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      child: InkWell(
                        onTap: () {
                          if (!item.isRead) {
                            db.markNotificationAsRead(item.id);
                            CustomFeedback.showToast(
                              context,
                              'Notification marked as read.',
                              type: 'success',
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: item.isRead 
                                  ? AppTheme.outlineVariant.withOpacity(0.8) 
                                  : AppTheme.primary.withOpacity(0.2),
                              width: item.isRead ? 1 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Notification Category Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item.isRead ? bg.withOpacity(0.5) : bg,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: Icon(
                                  icon, 
                                  color: item.isRead ? color.withOpacity(0.6) : color, 
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  fontWeight: item.isRead 
                                                      ? FontWeight.w600 
                                                      : FontWeight.bold,
                                                  color: item.isRead 
                                                      ? AppTheme.onSurface.withOpacity(0.7) 
                                                      : AppTheme.onSurface,
                                                ),
                                          ),
                                        ),
                                        // Unread Indicator Dot
                                        if (!item.isRead)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: item.isRead 
                                                ? AppTheme.onSurfaceVariant.withOpacity(0.7) 
                                                : AppTheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} - ${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: item.isRead 
                                                ? AppTheme.onSurfaceVariant.withOpacity(0.5) 
                                                : AppTheme.onSurfaceVariant.withOpacity(0.8),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
