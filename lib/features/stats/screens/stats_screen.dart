import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/widgets/volume_grass_widget.dart';

final _statsGrassProvider = FutureProvider<List<DailyGroupVolume>>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsNotifierProvider);
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 105));
  return db.getDailyGroupVolumes(
    userId: kLocalUserId,
    from: from,
    to: now,
    includeWarmup: settings.warmupInVolume,
  );
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grassAsync = ref.watch(_statsGrassProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Volume grass
          Text('볼륨 잔디', style: AppTextStyles.headingMd),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: grassAsync.when(
              data: (data) => VolumeGrassWidget(data: data),
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('오류: $e'),
            ),
          ),

          const SizedBox(height: 24),

          // Big 3 - 500 progress
          Text('3대 500', style: AppTextStyles.headingMd),
          const SizedBox(height: 12),
          _Big3Card(),

          const SizedBox(height: 24),

          // Muscle group donut
          Text('부위별 볼륨', style: AppTextStyles.headingMd),
          const SizedBox(height: 12),
          grassAsync.when(
            data: (data) => _DonutChart(data: data),
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('오류: $e'),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Big3Card extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder — will wire to one_rm table
    const big3 = [
      ('벤치프레스', 100.0, 500 / 3.0),
      ('데드리프트', 140.0, 500 / 3.0),
      ('스쿼트', 120.0, 500 / 3.0),
    ];
    final total = big3.fold(0.0, (s, e) => s + e.$2);
    final target = 500.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${total.toStringAsFixed(0)} kg',
                style: AppTextStyles.displaySm.copyWith(color: AppColors.accent),
              ),
              Text(' / ${target.toStringAsFixed(0)} kg', style: AppTextStyles.headingMd.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text('${(total / target * 100).toStringAsFixed(0)}%', style: AppTextStyles.numMd.copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 12),
          // Total progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (total / target).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceHigh,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          ...big3.map((e) => _Big3Row(name: e.$1, rm: e.$2)),
        ],
      ),
    );
  }
}

class _Big3Row extends StatelessWidget {
  final String name;
  final double rm;
  const _Big3Row({required this.name, required this.rm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(name, style: AppTextStyles.bodyMd)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (rm / 200.0).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.surfaceHigh,
                color: AppColors.accent.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '${rm.toStringAsFixed(0)} kg',
              style: AppTextStyles.numSm,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<DailyGroupVolume> data;
  const _DonutChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Aggregate by muscle group
    final Map<String, double> groupVol = {};
    for (final d in data) {
      groupVol[d.muscleGroup] = (groupVol[d.muscleGroup] ?? 0) + d.volumeKg;
    }
    if (groupVol.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('데이터가 없습니다', style: AppTextStyles.bodySm),
      );
    }

    final sections = groupVol.entries.map((e) {
      final color = AppColors.muscleGroupColor(e.key);
      return PieChartSectionData(
        value: e.value,
        color: color,
        title: e.key,
        titleStyle: AppTextStyles.bodySm.copyWith(color: Colors.white, fontSize: 10),
        radius: 60,
      );
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 50,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}
