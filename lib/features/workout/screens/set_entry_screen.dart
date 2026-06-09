import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/workout_session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_utils.dart';

class SetEntryScreen extends ConsumerStatefulWidget {
  final int workoutExerciseId;
  final String exerciseName;

  const SetEntryScreen({
    super.key,
    required this.workoutExerciseId,
    required this.exerciseName,
  });

  @override
  ConsumerState<SetEntryScreen> createState() => _SetEntryScreenState();
}

class _SetEntryScreenState extends ConsumerState<SetEntryScreen> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  bool _isWarmup = false;
  double? _rpe;
  String _unit = 'kg';
  int? _restSeconds;

  @override
  void initState() {
    super.initState();
    _unit = ref.read(settingsNotifierProvider).defaultUnit;
    _loadRestSeconds();
  }

  Future<void> _loadRestSeconds() async {
    // Get the exercise_id from the workout_exercise
    final db = ref.read(databaseProvider);
    final wes = await (db.select(db.workoutExercises)
          ..where((t) => t.id.equals(widget.workoutExerciseId)))
        .get();
    if (wes.isEmpty) return;
    final exs = await db.getExercisesByIds([wes.first.exerciseId]);
    if (exs.isNotEmpty && mounted) {
      setState(() => _restSeconds = exs.first.restSeconds);
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(setEntriesProvider(widget.workoutExerciseId));
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName, style: AppTextStyles.headingMd),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Previous sets / Current sets list
          Expanded(
            child: setsAsync.when(
              data: (sets) => _buildSetList(sets, settings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('오류: $e'),
            ),
          ),

          // Input area
          _buildInputArea(settings),
        ],
      ),
    );
  }

  Widget _buildSetList(List<SetEntry> sets, AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 36, child: Text('세트', style: AppTextStyles.labelMd, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              Expanded(child: Text('무게', style: AppTextStyles.labelMd, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              Expanded(child: Text('횟수', style: AppTextStyles.labelMd, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              SizedBox(width: 40, child: Text('완료', style: AppTextStyles.labelMd, textAlign: TextAlign.center)),
            ],
          ),
        ),
        const Divider(),
        ...sets.asMap().entries.map((entry) => _SetRow(
              set: entry.value,
              index: entry.key,
              displayUnit: settings.defaultUnit,
              showRpe: settings.showRpe,
              onDelete: () => _deleteSet(entry.value.id),
            )),
        if (sets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('첫 세트를 추가하세요', style: AppTextStyles.bodySm),
            ),
          ),
      ],
    );
  }

  Widget _buildInputArea(AppSettings settings) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Weight input
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('무게', style: AppTextStyles.labelMd),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      style: AppTextStyles.numMd,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: _unit,
                        suffixStyle: AppTextStyles.labelMd,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Reps input
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('횟수', style: AppTextStyles.labelMd),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _repsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTextStyles.numMd,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(suffixText: 'reps'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // kg/lb toggle
              Column(
                children: [
                  Text('단위', style: AppTextStyles.labelMd),
                  const SizedBox(height: 4),
                  _UnitToggle(
                    value: _unit,
                    onChanged: (u) => setState(() => _unit = u),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Warmup toggle
              GestureDetector(
                onTap: () => setState(() => _isWarmup = !_isWarmup),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isWarmup ? AppColors.warning.withOpacity(0.2) : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isWarmup ? AppColors.warning : AppColors.border),
                  ),
                  child: Text(
                    'W 워밍업',
                    style: AppTextStyles.labelMd.copyWith(
                      color: _isWarmup ? AppColors.warning : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              if (settings.showRpe) ...[
                const SizedBox(width: 8),
                _RpeSelector(value: _rpe, onChanged: (v) => setState(() => _rpe = v)),
              ],
              const Spacer(),
              // Add set button
              ElevatedButton(
                onPressed: _addSet,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Icon(Icons.check, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addSet() async {
    final weight = double.tryParse(_weightCtrl.text);
    final reps = int.tryParse(_repsCtrl.text);
    if (weight == null || reps == null || reps == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('무게와 횟수를 입력하세요')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final sets = await db.watchSets(widget.workoutExerciseId).first;
    final weightKg = toKg(weight, _unit);

    await db.addSet(
      userId: kLocalUserId,
      workoutExerciseId: widget.workoutExerciseId,
      setOrder: sets.length + 1,
      weightKg: weightKg,
      unit: _unit,
      reps: reps,
      isWarmup: _isWarmup,
      rpe: _rpe,
    );

    // Get rest seconds from exercise
    _weightCtrl.clear();
    _repsCtrl.clear();
    setState(() => _isWarmup = false);

    // Navigate to timer if auto-start
    final settings = ref.read(settingsNotifierProvider);
    if (settings.timerAutoStart && mounted) {
      context.push('/timer', extra: {
        'restSeconds': _restSeconds ?? 90,
        'exerciseName': widget.exerciseName,
      });
    }
  }

  Future<void> _deleteSet(int setId) async {
    final db = ref.read(databaseProvider);
    await db.deleteSet(setId);
  }
}

class _SetRow extends StatelessWidget {
  final SetEntry set;
  final int index;
  final String displayUnit;
  final bool showRpe;
  final VoidCallback onDelete;

  const _SetRow({
    required this.set,
    required this.index,
    required this.displayUnit,
    required this.showRpe,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(set.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error.withOpacity(0.2),
        child: const Icon(Icons.delete, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (set.isWarmup)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Center(child: Text('W', style: TextStyle(fontSize: 10, color: AppColors.warning))),
                    )
                  else
                    Text('${index + 1}', style: AppTextStyles.numSm.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${formatWeight(set.weightKg, displayUnit)} $displayUnit',
                style: AppTextStyles.numSm,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${set.reps} reps',
                style: AppTextStyles.numSm,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: Center(
                child: set.rpe != null && showRpe
                    ? Text('RPE\n${set.rpe!.toStringAsFixed(1)}', style: AppTextStyles.bodySm, textAlign: TextAlign.center)
                    : const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _UnitToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value == 'kg' ? 'lb' : 'kg'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(value, style: AppTextStyles.numSm.copyWith(color: AppColors.accent)),
      ),
    );
  }
}

class _RpeSelector extends StatelessWidget {
  final double? value;
  final ValueChanged<double?> onChanged;

  const _RpeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<double>(
          context: context,
          builder: (ctx) => _RpeDialog(current: value),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value != null ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          value != null ? 'RPE ${value!.toStringAsFixed(1)}' : 'RPE',
          style: AppTextStyles.labelMd.copyWith(
            color: value != null ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RpeDialog extends StatefulWidget {
  final double? current;
  const _RpeDialog({this.current});

  @override
  State<_RpeDialog> createState() => _RpeDialogState();
}

class _RpeDialogState extends State<_RpeDialog> {
  late double _val;

  @override
  void initState() {
    super.initState();
    _val = widget.current ?? 8.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('RPE 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_val.toStringAsFixed(1)}', style: AppTextStyles.displayMd.copyWith(color: AppColors.accent)),
          Slider(
            value: _val,
            min: 6.0,
            max: 10.0,
            divisions: 8,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _val = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('6.0 쉬움', style: AppTextStyles.labelSm),
              Text('10.0 최대', style: AppTextStyles.labelSm),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.current != null)
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('초기화')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _val),
          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
