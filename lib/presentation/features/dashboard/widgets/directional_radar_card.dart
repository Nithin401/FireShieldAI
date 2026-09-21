import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

class DirectionalRadarCard extends StatelessWidget {
  final int angle;
  final String fireState;
  final String responseStatus;
  final ValueChanged<int>? onAngleSelected;

  const DirectionalRadarCard({
    super.key,
    required this.angle,
    required this.fireState,
    required this.responseStatus,
    this.onAngleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isFire = fireState == 'FIRE';
    final isWarning = fireState == 'WARNING' || fireState == 'HIGH_RISK';
    final statusColor = isFire
        ? AppColors.error
        : (isWarning ? AppColors.warning : AppColors.primary);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFire ? AppColors.error.withValues(alpha: 0.8) : const Color(0xFF334155),
          width: isFire ? 2 : 1,
        ),
        boxShadow: isFire
            ? [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Directional Servo Radar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '$angle° ${isFire ? "🔥 LOCK-ON" : "SCANNING"}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _RadarCompassPainter(
                      needleAngle: angle.toDouble(),
                      color: statusColor,
                      isFire: isFire,
                    ),
                  ),
                  // Center Hub
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SERVO: $responseStatus',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'BEARING: ${_getCompassHeading(angle)}',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (onAngleSelected != null) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [0, 45, 90, 135, 180].map((deg) {
                final isSelected = angle == deg;
                return InkWell(
                  onTap: () => onAngleSelected!(deg),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? statusColor : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? statusColor : const Color(0xFF334155),
                      ),
                    ),
                    child: Text(
                      '$deg°',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getCompassHeading(int deg) {
    if (deg <= 22) return 'East (0°)';
    if (deg <= 67) return 'North-East (45°)';
    if (deg <= 112) return 'North (90°)';
    if (deg <= 157) return 'North-West (135°)';
    return 'West (180°)';
  }
}

class _RadarCompassPainter extends CustomPainter {
  final double needleAngle;
  final Color color;
  final bool isFire;

  _RadarCompassPainter({
    required this.needleAngle,
    required this.color,
    required this.isFire,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Concentric radar ranges
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.66, ringPaint);
    canvas.drawCircle(center, radius * 0.33, ringPaint);

    // Crosshairs
    final crosshairPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), crosshairPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), crosshairPaint);

    // Cardinal tick marks
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    void drawTick(String text, Offset pos) {
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2));
    }

    drawTick('90°', Offset(center.dx, center.dy - radius + 10));
    drawTick('0°', Offset(center.dx + radius - 12, center.dy));
    drawTick('180°', Offset(center.dx - radius + 12, center.dy));
    drawTick('45°', Offset(center.dx + radius * 0.65, center.dy - radius * 0.65));
    drawTick('135°', Offset(center.dx - radius * 0.65, center.dy - radius * 0.65));

    // Calculate needle angle in radians
    final rad = (180 - needleAngle) * (math.pi / 180.0);
    final targetX = center.dx + (radius - 14) * math.cos(rad);
    final targetY = center.dy - (radius - 14) * math.sin(rad);

    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    if (isFire) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, Offset(targetX, targetY), glowPaint);
    }

    canvas.drawLine(center, Offset(targetX, targetY), needlePaint);

    final tipPaint = Paint()
      ..color = isFire ? Colors.white : color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(targetX, targetY), isFire ? 5 : 4, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarCompassPainter oldDelegate) {
    return oldDelegate.needleAngle != needleAngle ||
        oldDelegate.color != color ||
        oldDelegate.isFire != isFire;
  }
}
