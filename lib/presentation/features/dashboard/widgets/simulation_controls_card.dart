import 'package:flutter/material.dart';
import 'package:fireshield_app/core/theme/app_colors.dart';

class SimulationControlsCard extends StatelessWidget {
  final ValueChanged<String> onSimulate;
  final String currentScenario;

  const SimulationControlsCard({
    super.key,
    required this.onSimulate,
    this.currentScenario = 'NORMAL',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science, color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Event Testing Injector',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Inject real sensor states directly into AI Risk Engine',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Button 1: Normal
              Expanded(
                child: _buildSimButton(
                  label: 'NORMAL',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  isActive: currentScenario == 'NORMAL',
                  onTap: () => onSimulate('NORMAL'),
                ),
              ),
              const SizedBox(width: 8),

              // Button 2: False Alarm
              Expanded(
                child: _buildSimButton(
                  label: 'FALSE ALARM',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  isActive: currentScenario == 'FALSE_ALARM',
                  onTap: () => onSimulate('FALSE_ALARM'),
                ),
              ),
              const SizedBox(width: 8),

              // Button 3: Fire Event
              Expanded(
                child: _buildSimButton(
                  label: 'FIRE EVENT',
                  icon: Icons.local_fire_department,
                  color: AppColors.error,
                  isActive: currentScenario == 'FIRE',
                  onTap: () => onSimulate('FIRE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : const Color(0xFF334155),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
