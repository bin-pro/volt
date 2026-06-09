import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
// AppSettings used via settingsNotifierProvider
import '../../../core/theme/app_theme.dart';
import '../widgets/volume_grass_widget.dart';
import '../widgets/weekly_volume_bar.dart';

final _weeklyVolumeProvider = FutureProvider<List<DailyGroupVolume>>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsNotifierProvider);
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return db.getDailyGroupVolumes(
    userId: kLocalUserId,
    from: monday,
    to: now,
    includeWarmup: settings.warmupInVolume,
  );
});

final _grassVolumeProvider = FutureProvider<List<DailyGroupVolume>>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsNotifierProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1); // 이번 달 1일
  return db.getDailyGroupVolumes(
    userId: kLocalUserId,
    from: from,
    to: now,
    includeWarmup: settings.warmupInVolume,
  );
});

final _recentWorkoutsProvider = StreamProvider<List<Workout>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentWorkouts(kLocalUserId, limit: 5);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(_weeklyVolumeProvider);
    final grassAsync = ref.watch(_grassVolumeProvider);
    final recentAsync = ref.watch(_recentWorkoutsProvider);
    final settings = ref.watch(settingsNotifierProvider); // AppSettings

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            title: RichText(
              text: const TextSpan(
                style: TextStyle(fontFamily: 'Anton', fontSize: 22, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'VO'),
                  TextSpan(text: 'L', style: TextStyle(color: AppColors.accent)),
                  TextSpan(text: 'T'),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weekly volume bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: weeklyAsync.when(
                      data: (data) {
                        final weekDays = List.filled(7, 0.0);
                        for (final d in data) {
                          final idx = d.date.weekday - 1; // 0=Mon
                          if (idx >= 0 && idx < 7) weekDays[idx] += d.volumeKg;
                        }
                        return WeeklyVolumeBar(dayVolumes: weekDays, unit: settings.defaultUnit);
                      },
                      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => Text('오류: $e', style: AppTextStyles.bodySm),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Grass
                  Text('볼륨 잔디', style: AppTextStyles.headingSm),
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
                      error: (e, _) => Text('오류: $e', style: AppTextStyles.bodySm),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent sessions
                  Text('최근 세션', style: AppTextStyles.headingSm),
                  const SizedBox(height: 12),
                  recentAsync.when(
                    data: (workouts) {
                      if (workouts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.fitness_center, size: 48, color: AppColors.textTertiary),
                                const SizedBox(height: 12),
                                Text('아직 기록이 없습니다', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                Text('첫 운동을 시작해보세요!', style: AppTextStyles.bodySm),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: workouts.map((w) => _WorkoutCard(workout: w)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('오류: $e', style: AppTextStyles.bodySm),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/session/muscles'),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final date = workout.date;
    final duration = workout.endedAt != null && workout.startedAt != null
        ? workout.endedAt!.difference(workout.startedAt!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.month}/${date.day} (${_weekday(date.weekday)})',
                style: AppTextStyles.headingSm,
              ),
              if (duration != null)
                Text(
                  '${duration.inMinutes}분',
                  style: AppTextStyles.bodySm,
                ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  String _weekday(int w) {
    const days = ['', '월', '화', '수', '목', '금', '토', '일'];
    return days[w];
  }
}
