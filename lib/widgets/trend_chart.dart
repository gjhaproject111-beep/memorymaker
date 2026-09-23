import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// A small, self-contained line chart (no external charting package) for
/// showing a metric's trend over a handful of buckets — deliberately plain
/// rather than "fake precise": it draws exactly the points it is given.
class TrendLineChart extends StatelessWidget {
  final List<double> values; // 0..1 range expected, but not enforced
  final List<String> labels;
  final double height;
  final Color color;
  final String Function(double)? valueFormat;

  const TrendLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 160,
    this.color = AppColors.peach,
    this.valueFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Not enough data yet', style: AppTextStyles.bodySecondary),
        ),
      );
    }
    final format = valueFormat ?? (v) => '${(v * 100).round()}%';
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _TrendPainter(values: values, color: color),
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (values.isNotEmpty)
                Text(format(values.last), style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _TrendPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 24; // leave room for the value label
    final top = 20.0;
    final maxV = values.reduce((a, b) => a > b ? a : b).clamp(0.0001, double.infinity);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final dx = values.length > 1 ? size.width / (values.length - 1) : 0.0;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] - minV) / range;
      final y = top + chartHeight - (normalized * chartHeight);
      final x = values.length > 1 ? dx * i : size.width / 2;
      points.add(Offset(x, y));
    }

    // Gridlines
    final gridPaint = Paint()
      ..color = AppColors.plumBorder
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = top + chartHeight * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.length == 1) {
      canvas.drawCircle(points.first, 4, Paint()..color = color);
      return;
    }

    // Filled area under the line, subtle.
    final fillPath = Path()..moveTo(points.first.dx, top + chartHeight);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, top + chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = color.withOpacity(0.12));

    // The line itself.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final p in points) {
      canvas.drawCircle(p, 3.5, Paint()..color = color);
      canvas.drawCircle(p, 3.5, Paint()
        ..color = AppColors.deepPlum
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.values != values;
}

/// A simple horizontal bar list — used for error-type breakdowns, where a
/// bar chart reads more clearly than a line.
class BarBreakdown extends StatelessWidget {
  final List<({String label, double value, Color color})> items;
  const BarBreakdown({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final maxV = items.isEmpty ? 1.0 : items.map((e) => e.value).fold(0.0001, (a, b) => a > b ? a : b);
    return Column(
      children: items.map((item) {
        final fraction = maxV == 0 ? 0.0 : (item.value / maxV).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text(item.label, style: AppTextStyles.bodySecondary)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(height: 8, color: AppColors.plumBorder),
                        Container(height: 8, width: constraints.maxWidth * fraction, color: item.color),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                child: Text('${(item.value * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.caption, textAlign: TextAlign.right),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
