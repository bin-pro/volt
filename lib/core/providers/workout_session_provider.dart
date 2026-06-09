import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

// 현재 진행 중인 워크아웃 세션 ID
final activeWorkoutProvider = StateProvider<int?>((ref) => null);

// 현재 진행 중인 종목 순서 (workout_exercise.id 기준)
final activeWorkoutExerciseProvider = StateProvider<int?>((ref) => null);

// 종목 선택 시 순서 보존 (exercise_id → order_index)
final selectedExercisesProvider = StateProvider<List<int>>((ref) => []);

// 현재 세션의 workout_exercises
final workoutExercisesProvider = StreamProvider.family<List<WorkoutExercise>, int>(
  (ref, workoutId) {
    final db = ref.watch(databaseProvider);
    return db.watchWorkoutExercises(workoutId);
  },
);

// 세트 목록
final setEntriesProvider = StreamProvider.family<List<SetEntry>, int>(
  (ref, workoutExerciseId) {
    final db = ref.watch(databaseProvider);
    return db.watchSets(workoutExerciseId);
  },
);
