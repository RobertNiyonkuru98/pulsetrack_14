import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One ring segment: a colour and how much of the ring it takes.
class DonutSlice {
  const DonutSlice({required this.value, required this.color, required this.label});

  final double value;
  final Color color;
  final String label;
}

/// A donut chart drawn with a CustomPainter - no charting dependency needed.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.slices, this.size = 140});

  final List<DonutSlice> slices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double total =
        slices.fold<double>(0, (double sum, DonutSlice s) => sum + s.value);

    if (total <= 0) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Text('No data', style: TextStyle(color: AppColors.muted)),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(slices: slices, total: total),
        child: Center(
          child: Text(
            total.toInt().toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.total});

  final List<DonutSlice> slices;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.width * 0.18;
    final Rect rect = Rect.fromLTWH(
      stroke / 2 + size.width * 0.05,
      stroke / 2 + size.height * 0.05,
      size.width - stroke - size.width * 0.10,
      size.height - stroke - size.height * 0.10,
    );

    double start = -math.pi / 2;
    for (final DonutSlice slice in slices) {
      if (slice.value <= 0) continue;
      final double sweep = (slice.value / total) * math.pi * 2;
      final Paint paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
