import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const CustomBottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<CustomBottomBarItem> items;
  final ValueChanged<int> onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: AppTheme.outlineVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = index == currentIndex;

          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(999),
            splashColor: AppTheme.primary.withOpacity(0.05),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryContainer.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive ? AppTheme.primary : AppTheme.secondary,
                    size: 22,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    AnimatedOpacity(
                      opacity: isActive ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
