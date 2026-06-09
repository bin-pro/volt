import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class WeeklyVolumeBar extends StatelessWidget {
  /// day volumes: index 0=Mon, 6=Sun, value is total kg
  final List<double> dayVolumes;
  final String unit;

  const WeeklyVolumeBar({super.key, required this.dayVolumes, this.unit = 'kg'});

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final max = dayVolumes.isEmpty ? 1.0 : dayVolumes.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    final total = dayVolumes.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final vol = i < dayVolumes.length ? dayVolumes[i] : 0.0;
            final ratio = vol / max;
            final isToday = i == (DateTime.now().weekday - 1);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    Container(
                      height: 64 * ratio,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.accent : AppColors.surfaceHigher,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[i],
                      style: AppTextStyles.labelSm.copyWith(
                        color: isToday ? AppColors.accent : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('이번주 총 볼륨', style: AppTextStyles.labelMd),
            const Spacer(),
            Text(
              '${_format(total)} $unit',
              style: AppTextStyles.numMd.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ],
    );
  }

  String _format(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}t';
    return v.toStringAsFixed(0);
  }
}
