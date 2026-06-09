import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/workout_session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/chosung_utils.dart';

// Exercise list provider with group filter + search
final _exerciseListProvider = StreamProvider.family<List<Exercise>, String?>(
  (ref, group) => ref.watch(databaseProvider).watchExercises(group: group),
);

class ExerciseSelectScreen extends ConsumerStatefulWidget {
  final List<String> selectedGroups;
  const ExerciseSelectScreen({super.key, required this.selectedGroups});

  @override
  ConsumerState<ExerciseSelectScreen> createState() => _ExerciseSelectScreenState();
}

class _ExerciseSelectScreenState extends ConsumerState<ExerciseSelectScreen> {
  String _query = '';
  String? _activeGroupFilter;
  final List<int> _selectedOrder = []; // exercise ids in selection order

  @override
  Widget build(BuildContext context) {
    // Use first group as default filter
    _activeGroupFilter ??= widget.selectedGroups.isNotEmpty ? widget.selectedGroups.first : null;

    final exercisesAsync = ref.watch(_exerciseListProvider(_activeGroupFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('종목 선택'),
        actions: [
          if (_selectedOrder.isNotEmpty)
            TextButton(
              onPressed: _startWorkout,
              child: Text('시작 (${_selectedOrder.length})', style: AppTextStyles.headingSm.copyWith(color: AppColors.accent)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: '종목 검색 (초성 가능: ㅂㅊㅍ)',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),

          // Group filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: widget.selectedGroups.map((g) {
                final isActive = _activeGroupFilter == g;
                final color = AppColors.muscleGroupColor(g);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(g),
                    selected: isActive,
                    onSelected: (_) => setState(() => _activeGroupFilter = isActive ? null : g),
                    selectedColor: color.withOpacity(0.25),
                    checkmarkColor: color,
                    labelStyle: AppTextStyles.bodyMd.copyWith(
                      color: isActive ? color : AppColors.textSecondary,
                    ),
                    side: BorderSide(color: isActive ? color : AppColors.border),
                  ),
                );
              }).toList(),
            ),
          ),

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                final filtered = exercises.where((e) =>
                    widget.selectedGroups.contains(e.muscleGroup) &&
                    matchesQuery(e.name, e.chosung, _query)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('검색 결과 없음', style: AppTextStyles.bodySm),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final ex = filtered[i];
                    final orderIdx = _selectedOrder.indexOf(ex.id);
                    final isSelected = orderIdx >= 0;
                    final groupColor = AppColors.muscleGroupColor(ex.muscleGroup);

                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: groupColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isSelected
                            ? Center(
                                child: Text(
                                  '${orderIdx + 1}',
                                  style: AppTextStyles.numSm.copyWith(color: groupColor, fontWeight: FontWeight.bold),
                                ),
                              )
                            : Icon(Icons.fitness_center, color: groupColor, size: 18),
                      ),
                      title: Text(ex.name, style: AppTextStyles.bodyMd),
                      subtitle: Text(
                        '${ex.muscleGroup} · ${ex.equipment ?? ''} · ${ex.restSeconds}s',
                        style: AppTextStyles.bodySm,
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: groupColor)
                          : const Icon(Icons.add_circle_outline, color: AppColors.textTertiary),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedOrder.remove(ex.id);
                          } else {
                            _selectedOrder.add(ex.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('오류: $e'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedOrder.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _startWorkout,
                  child: Text('${_selectedOrder.length}개 종목으로 운동 시작'),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _startWorkout() async {
    if (_selectedOrder.isEmpty) return;

    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();

      final workout = await db.createWorkout(userId: kLocalUserId, date: now);

      for (var i = 0; i < _selectedOrder.length; i++) {
        await db.addExerciseToWorkout(
          userId: kLocalUserId,
          workoutId: workout.id,
          exerciseId: _selectedOrder[i],
          orderIndex: i,
        );
      }

      ref.read(activeWorkoutProvider.notifier).state = workout.id;
      ref.read(selectedExercisesProvider.notifier).state = List.from(_selectedOrder);

      if (mounted) context.go('/workout');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
