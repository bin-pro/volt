import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/workout_session_provider.dart';
import '../../../core/theme/app_theme.dart';

class ExerciseTile extends ConsumerWidget {
  final WorkoutExercise workoutExercise;
  final VoidCallback onTap;

  const ExerciseTile({
    super.key,
    required this.workoutExercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(setEntriesProvider(workoutExercise.id));
    final exerciseFuture = ref.watch(
      _exerciseNameProvider(workoutExercise.exerciseId),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accentDim.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${workoutExercise.orderIndex + 1}',
                      style: AppTextStyles.numSm.copyWith(
                        color: AppColors.accent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: exerciseFuture.when(
                    data: (name) => Text(name, style: AppTextStyles.headingSm),
                    loading: () => const SizedBox(height: 16, width: 100, child: LinearProgressIndicator()),
                    error: (_, __) => const Text('종목'),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            setsAsync.when(
              data: (sets) {
                if (sets.isEmpty) {
                  return Text('세트 없음 — 탭하여 기록', style: AppTextStyles.bodySm);
                }
                final done = sets.length;
                final totalVol = sets.fold(0.0, (s, e) => s + e.weightKg * e.reps);
                return Row(
                  children: [
                    _Chip('${done}세트'),
                    const SizedBox(width: 8),
                    _Chip('${totalVol.toStringAsFixed(0)} kg'),
                  ],
                );
              },
              loading: () => const SizedBox(height: 20),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTextStyles.bodySm),
    );
  }
}

// Provider to get exercise name by id
final _exerciseNameProvider = FutureProvider.family<String, int>((ref, exerciseId) async {
  final db = ref.watch(databaseProvider);
  final exs = await db.getExercisesByIds([exerciseId]);
  return exs.isNotEmpty ? exs.first.name : '알 수 없음';
});
