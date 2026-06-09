import 'package:go_router/go_router.dart';
import 'features/home/screens/home_screen.dart';
import 'features/session/screens/muscle_group_select_screen.dart';
import 'features/session/screens/exercise_select_screen.dart';
import 'features/workout/screens/workout_screen.dart';
import 'features/workout/screens/set_entry_screen.dart';
import 'features/timer/timer_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'shell/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/workout', builder: (c, s) => const WorkoutScreen()),
        GoRoute(path: '/stats', builder: (c, s) => const StatsScreen()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      ],
    ),
    GoRoute(
      path: '/session/muscles',
      builder: (c, s) => const MuscleGroupSelectScreen(),
    ),
    GoRoute(
      path: '/session/exercises',
      builder: (c, s) {
        final groups = (s.extra as List<String>?) ?? [];
        return ExerciseSelectScreen(selectedGroups: groups);
      },
    ),
    GoRoute(
      path: '/workout/sets/:weId',
      builder: (c, s) {
        final weId = int.parse(s.pathParameters['weId']!);
        final exerciseName = s.extra as String? ?? '';
        return SetEntryScreen(workoutExerciseId: weId, exerciseName: exerciseName);
      },
    ),
    GoRoute(
      path: '/timer',
      builder: (c, s) {
        final args = s.extra as Map<String, dynamic>? ?? {};
        return TimerScreen(
          restSeconds: args['restSeconds'] as int? ?? 90,
          exerciseName: args['exerciseName'] as String? ?? '',
        );
      },
    ),
  ],
);
