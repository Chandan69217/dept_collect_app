import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBentoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final BorderSide? borderSide;
  final double? height;
  final double padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? backgroundDecoration;

  const CustomBentoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderSide,
    this.height,
    this.padding = 16.0,
    this.onTap,
    this.onLongPress,
    this.backgroundDecoration,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: EdgeInsets.all(padding),
      child: child,
    );

    if (backgroundDecoration != null) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            backgroundDecoration is Positioned
                ? backgroundDecoration!
                : Positioned.fill(child: backgroundDecoration!),
            cardContent,
          ],
        ),
      );
    }

    final boxDecoration = BoxDecoration(
      color: backgroundColor ?? AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.fromBorderSide(
        borderSide ?? const BorderSide(color: AppTheme.outlineVariant, width: 1),
      ),
    );

    return Container(
      height: height,
      decoration: boxDecoration,
      child: onTap != null || onLongPress != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: cardContent,
              ),
            )
          : cardContent,
    );
  }
}
