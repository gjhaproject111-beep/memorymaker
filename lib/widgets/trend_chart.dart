import 'dart:math' show pi;

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
    this.labels = const [],
    this.height = 160,
    this.color = AppColors.peachAccent,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(format(values.last), style: AppTextStyles.statNumber.copyWith(color: color, fontSize: 20)),
        const SizedBox(height: 6),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _TrendPainter(values: values, color: color)),
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 6),
          _TrendLabelsRow(labels: labels, pointCount: values.length),
        ],
      ],
    );
  }
}

/// Renders a thinned-out row of x-axis labels — evenly spaced slots so they
/// roughly line up with the (also evenly spaced) plotted points, without
/// crowding the axis when there are many buckets.
class _TrendLabelsRow extends StatelessWidget {
  final List<String> labels;
  final int pointCount;
  const _TrendLabelsRow({required this.labels, required this.pointCount});

  static const int _maxShown = 6;

  @override
  Widget build(BuildContext context) {
    final slots = pointCount > 0 ? pointCount : labels.length;
    final step = labels.length > _maxShown ? (labels.length / _maxShown).ceil() : 1;
    return Row(
      children: List.generate(slots, (i) {
        final text = (i < labels.length && (i % step == 0 || i == labels.length - 1)) ? labels[i] : '';
        return Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _TrendPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 8;
    const top = 4.0;
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

    // Gridlines.
    final gridPaint = Paint()
      ..color = AppColors.border
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
    canvas.drawPath(fillPath, Paint()..color = color.withOpacity(0.10));

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

    // Clean "white dot, colored ring" markers — reads well against both the
    // card surface and the line/fill beneath it.
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = AppColors.surface);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
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
              SizedBox(
                width: 100,
                child: Text(item.label, style: AppTextStyles.bodySecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(height: 8, color: AppColors.background),
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

/// A multi-segment donut chart with a legend — used for Analytics' "Common
/// Mistakes" breakdown, matching the reference design's ring-plus-list
/// layout.
class DonutBreakdown extends StatelessWidget {
  final List<({String label, double value, Color color})> items;
  final String centerValue;
  final String centerLabel;

  const DonutBreakdown({
    super.key,
    required this.items,
    required this.centerValue,
    required this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 116,
          height: 116,
          child: CustomPaint(
            painter: _DonutPainter(items: items),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(centerValue, style: AppTextStyles.statNumber.copyWith(fontSize: 20)),
                  Text(centerLabel, style: AppTextStyles.caption, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.label,
                          style: AppTextStyles.bodySecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text('${(item.value * 100).toStringAsFixed(1)}%', style: AppTextStyles.caption),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<({String label, double value, Color color})> items;
  _DonutPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<double>(0, (sum, i) => sum + i.value);
    final strokeWidth = size.width * 0.16;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(strokeWidth / 2);

    if (total <= 0) {
      canvas.drawArc(
        rect,
        0,
        2 * pi,
        false,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    var start = -pi / 2;
    for (final item in items) {
      if (item.value <= 0) continue;
      final sweep = 2 * pi * (item.value / total);
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = item.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.items != items;
}
