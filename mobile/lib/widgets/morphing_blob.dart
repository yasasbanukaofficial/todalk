import 'dart:math';
import 'package:flutter/material.dart';

class MorphingBlob extends StatelessWidget {
  final double amplitude;
  final double phase;
  final double soundLevel;
  final double size;

  const MorphingBlob({
    super.key,
    required this.amplitude,
    required this.phase,
    this.soundLevel = 0,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BlobPainter(
          amplitude: amplitude,
          phase: phase,
          soundLevel: soundLevel,
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double amplitude;
  final double phase;
  final double soundLevel;

  _BlobPainter({
    required this.amplitude,
    required this.phase,
    this.soundLevel = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) / 2 * 0.7;
    final effectiveAmp = (amplitude + soundLevel * 0.6).clamp(0.0, 1.0);
    final maxWobble = baseRadius * 0.15;
    final glowRadius = baseRadius * 1.15;

    final path = _buildBlobPath(center, baseRadius, maxWobble, effectiveAmp);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.12 + effectiveAmp * 0.08),
          Colors.white.withValues(alpha: 0.04),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, glowRadius, glowPaint);

    final secondaryGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0),
        radius: 0.7,
        colors: [
          Colors.white.withValues(alpha: 0.06 + effectiveAmp * 0.04),
          Colors.white.withValues(alpha: 0.02),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius * 1.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, glowRadius * 1.3, secondaryGlow);

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  Path _buildBlobPath(Offset center, double baseRadius, double maxWobble, double amp) {
    const n = 80;
    final points = <Offset>[];

    for (int i = 0; i < n; i++) {
      final theta = (i / n) * 2 * pi;
      final wobble = sin(theta * 4 + phase * 2.5) * 0.7
          + sin(theta * 7 + phase * 1.8) * 0.4
          + sin(theta * 11 + phase * 4.0) * 0.15
          + sin(theta * 3 + phase * 1.2) * 0.3;
      final r = baseRadius + wobble * maxWobble * amp;
      points.add(Offset(
        center.dx + r * cos(theta),
        center.dy + r * sin(theta),
      ));
    }

    final path = Path();
    for (int i = 0; i < n; i++) {
      final p0 = points[(i - 1 + n) % n];
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      final p3 = points[(i + 2) % n];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      }
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) =>
      old.amplitude != amplitude ||
      old.phase != phase ||
      old.soundLevel != soundLevel;
}
