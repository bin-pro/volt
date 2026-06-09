import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';

class VolumeGrassWidget extends StatelessWidget {
  final List<DailyGroupVolume> data;

  const VolumeGrassWidget({super.key, required this.data});

  static const double _cell = 14;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    // 볼륨 맵
    final Map<String, _DayData> dayMap = {};
    for (final d in data) {
      final key = _key(d.date);
      final existing = dayMap[key];
      if (existing == null || d.volumeKg > existing.vol) {
        dayMap[key] = _DayData(d.groupColor, d.volumeKg);
      }
    }
    double maxVol = 0;
    for (final d in dayMap.values) {
      if (d.vol > maxVol) maxVol = d.vol;
    }

    // 월요일 기준 시작 오프셋 (0=월 … 6=일)
    final startOffset = (firstOfMonth.weekday - 1) % 7;
    final totalCells = startOffset + lastDay;
    final totalWeeks = (totalCells / 7).ceil();

    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${now.year}년 ${now.month}월',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
            Text('${lastDay}일', style: AppTextStyles.labelSm),
          ],
        ),
        const SizedBox(height: 10),
        // 요일 라벨 + 셀 그리드
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요일 라벨 컬럼
            Column(
              children: dayLabels.map((l) => SizedBox(
                width: 14,
                height: _cell + _gap,
                child: Center(
                  child: Text(l, style: AppTextStyles.labelSm.copyWith(fontSize: 9)),
                ),
              )).toList(),
            ),
            const SizedBox(width: 4),
            // 주(week) 컬럼들
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(totalWeeks, (weekIdx) {
                return Padding(
                  padding: EdgeInsets.only(right: weekIdx < totalWeeks - 1 ? _gap : 0),
                  child: Column(
                    children: List.generate(7, (dayIdx) {
                      final cellIdx = weekIdx * 7 + dayIdx;
                      final dayNum = cellIdx - startOffset + 1;
                      final isValid = dayNum >= 1 && dayNum <= lastDay;
                      final date = isValid ? DateTime(now.year, now.month, dayNum) : null;
                      final isToday = date != null && date == today;
                      final isFuture = date != null && date.isAfter(today);

                      Color cellColor;
                      if (!isValid || isFuture) {
                        cellColor = Colors.transparent;
                      } else {
                        final d = dayMap[_key(date!)];
                        cellColor = d == null
                            ? AppColors.surfaceHigh
                            : _intensity(d.color, d.vol, maxVol);
                      }

                      return Container(
                        width: _cell,
                        height: _cell,
                        margin: EdgeInsets.only(bottom: dayIdx < 6 ? _gap : 0),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(3),
                          border: isToday
                              ? Border.all(color: AppColors.accent, width: 1.5)
                              : null,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _legend(),
      ],
    );
  }

  Color _intensity(String hex, double vol, double maxVol) {
    if (maxVol == 0) return AppColors.surfaceHigh;
    final base = _fromHex(hex);
    final r = vol / maxVol;
    if (r < 0.33) return base.withValues(alpha: 0.40);
    if (r < 0.66) return base.withValues(alpha: 0.70);
    return base;
  }

  Color _fromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _legend() {
    const groups = [
      ('가슴', AppColors.chest),
      ('등', AppColors.back),
      ('어깨', AppColors.shoulder),
      ('팔', AppColors.arm),
      ('하체', AppColors.leg),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: groups.map((g) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: g.$2, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(g.$1, style: AppTextStyles.labelSm),
        ],
      )).toList(),
    );
  }
}

class _DayData {
  final String color;
  final double vol;
  const _DayData(this.color, this.vol);
}
