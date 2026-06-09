import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/workout_session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/exercise_tile.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutId = ref.watch(activeWorkoutProvider);

    if (workoutId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text('진행 중인 운동이 없습니다', style: AppTextStyles.bodyLg.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/session/muscles'),
                icon: const Icon(Icons.add),
                label: const Text('운동 시작'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
              ),
            ],
          ),
        ),
      );
    }

    final exercisesAsync = ref.watch(workoutExercisesProvider(workoutId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 중'),
        actions: [
          TextButton(
            onPressed: () => _confirmEnd(context, ref, workoutId),
            child: Text('종료', style: AppTextStyles.headingSm.copyWith(color: AppColors.error)),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/session/muscles'),
            tooltip: '종목 추가',
          ),
        ],
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(child: Text('종목이 없습니다', style: AppTextStyles.bodyMd));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            onReorder: (oldIdx, newIdx) async {
              // Reorder logic would update order_index in DB
            },
            itemBuilder: (context, i) {
              final we = exercises[i];
              return ExerciseTile(
                key: ValueKey(we.id),
                workoutExercise: we,
                onTap: () async {
                  final db = ref.read(databaseProvider);
                  final exs = await db.getExercisesByIds([we.exerciseId]);
                  final name = exs.isNotEmpty ? exs.first.name : '';
                  if (context.mounted) {
                    context.push('/workout/sets/${we.id}', extra: name);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('오류: $e'),
      ),
    );
  }

  void _confirmEnd(BuildContext context, WidgetRef ref, int workoutId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('운동 종료'),
        content: const Text('오늘 운동을 마치겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.endWorkout(workoutId);
              ref.read(activeWorkoutProvider.notifier).state = null;
              ref.read(selectedExercisesProvider.notifier).state = [];
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go('/');
            },
            child: Text('종료', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
