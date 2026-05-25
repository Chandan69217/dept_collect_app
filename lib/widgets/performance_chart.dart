import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ChartType { gauge, trend }

class PerformanceChart extends StatefulWidget {
  final ChartType type;
  final double value; // for gauge (0.0 to 1.0)
  final List<double>? dataPoints; // for trend
  final String? centerText;

  const PerformanceChart({
    super.key,
    required this.type,
    this.value = 0.72,
    this.dataPoints,
    this.centerText,
  });

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(PerformanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(CurvedAnimation(
              parent: _controller, curve: Curves.easeInOutCubic));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == ChartType.gauge) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(110, 110),
            painter: _GaugePainter(
              percentage: _animation.value,
              trackColor: Colors.white.withOpacity(0.2),
              progressColor: Colors.white,
            ),
            child: Center(
              child: widget.centerText != null
                  ? Text(
                      widget.centerText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          );
        },
      );
    } else {
      // Trend Line Mode
      final points = widget.dataPoints ?? [30, 45, 38, 60, 52, 72, 85];
      return CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _TrendPainter(
          points: points,
          lineColor: AppTheme.primary,
          fillColor: AppTheme.primaryContainer.withOpacity(0.1),
        ),
      );
    }
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;

  _GaugePainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) + 9;
    final strokeWidth = 3.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw arc from top ( -pi / 2 )
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final Color fillColor;

  _TrendPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final segmentWidth = width / (points.length - 1);
    final maxVal = points.reduce(max);
    final minVal = points.reduce(min);
    final range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    // Map points to offsets
    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = i * segmentWidth;
      // Normalize y to height, keeping padding
      final normalizedY = 1.0 - ((points[i] - minVal) / range);
      final y = 10 + normalizedY * (height - 20);
      offsets.add(Offset(x, y));
    }

    // Path for trend line
    final linePath = Path()..moveTo(offsets[0].dx, offsets[0].dy);
    for (var i = 1; i < offsets.length; i++) {
      // Smooth out curve using cubic beziers
      final prev = offsets[i - 1];
      final current = offsets[i];
      final controlPoint1 = Offset(prev.dx + (current.dx - prev.dx) / 2, prev.dy);
      final controlPoint2 = Offset(prev.dx + (current.dx - prev.dx) / 2, current.dy);
      linePath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        current.dx, current.dy,
      );
    }

    // Path for filled gradient under the line
    final fillPath = Path()
      ..addPath(linePath, Offset.zero)
      ..lineTo(offsets.last.dx, height)
      ..lineTo(offsets.first.dx, height)
      ..close();

    // Draw fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.2),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(linePath, linePaint);

    // Draw tiny dots on points
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var offset in offsets) {
      canvas.drawCircle(offset, 4, dotPaint);
      canvas.drawCircle(offset, 4, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
