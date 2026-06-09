import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../utils/uuid_utils.dart';

part 'app_database.g.dart';

// ── Tables ──────────────────────────────────────────────────

class MuscleGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get color => text()();
  BoolColumn get countsVolume => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get equipment => text().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  TextColumn get inputType => text().withDefault(const Constant('weight'))();
  BoolColumn get countsVolume => boolean().withDefault(const Constant(true))();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get chosung => text().withDefault(const Constant(''))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get syncId => text().unique()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get syncId => text().unique()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class SetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get syncId => text().unique()();
  IntColumn get workoutExerciseId => integer().references(WorkoutExercises, #id)();
  IntColumn get setOrder => integer()();
  RealColumn get weightKg => real()();
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  IntColumn get reps => integer()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  RealColumn get rpe => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class CardioEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get syncId => text().unique()();
  IntColumn get workoutExerciseId => integer().references(WorkoutExercises, #id)();
  IntColumn get durationSec => integer()();
  RealColumn get intensity => real().nullable()();
  RealColumn get incline => real().nullable()();
  RealColumn get distanceKm => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class OneRms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get syncId => text().unique()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class UserSettings extends Table {
  TextColumn get userId => text()();
  TextColumn get defaultUnit => text().withDefault(const Constant('kg'))();
  BoolColumn get warmupInVolume => boolean().withDefault(const Constant(false))();
  BoolColumn get showRpe => boolean().withDefault(const Constant(true))();
  BoolColumn get timerAutoStart => boolean().withDefault(const Constant(true))();
  BoolColumn get timerSound => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}

// ── Database ─────────────────────────────────────────────────

@DriftDatabase(tables: [
  MuscleGroups,
  Exercises,
  Workouts,
  WorkoutExercises,
  SetEntries,
  CardioEntries,
  OneRms,
  UserSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedData();
    },
  );

  Future<void> _seedData() async {
    // Seed muscle groups
    final mgData = [
      (name: '가슴', color: '#FF6B6B', countsVolume: true, sortOrder: 0),
      (name: '등', color: '#4ECDC4', countsVolume: true, sortOrder: 1),
      (name: '어깨', color: '#FFBE0B', countsVolume: true, sortOrder: 2),
      (name: '팔', color: '#FF9F1C', countsVolume: true, sortOrder: 3),
      (name: '하체', color: '#2EC4B6', countsVolume: true, sortOrder: 4),
      (name: '복근', color: '#8B5CF6', countsVolume: false, sortOrder: 5),
      (name: '유산소', color: '#6B7280', countsVolume: false, sortOrder: 6),
    ];
    for (final mg in mgData) {
      await into(muscleGroups).insertOnConflictUpdate(
        MuscleGroupsCompanion.insert(
          name: mg.name,
          color: mg.color,
          countsVolume: Value(mg.countsVolume),
          sortOrder: Value(mg.sortOrder),
        ),
      );
    }

    // Seed exercises from asset
    final jsonStr = await rootBundle.loadString('assets/data/exercises_seed.json');
    final List<dynamic> exercises = jsonDecode(jsonStr);
    for (final ex in exercises) {
      await into(this.exercises).insertOnConflictUpdate(
        ExercisesCompanion.insert(
          name: ex['name'] as String,
          muscleGroup: ex['group'] as String,
          equipment: Value(ex['equipment'] as String?),
          restSeconds: Value(ex['restSeconds'] as int? ?? 90),
          inputType: Value(ex['inputType'] as String? ?? 'weight'),
          countsVolume: Value(ex['countsVolume'] as bool? ?? true),
          tags: Value(jsonEncode(ex['tags'] ?? [])),
          chosung: Value(ex['chosung'] as String? ?? ''),
        ),
      );
    }
  }

  // ── Workout queries ───────────────────────────────────────

  Future<Workout> createWorkout({required String userId, required DateTime date}) {
    final now = DateTime.now();
    return into(workouts).insertReturning(
      WorkoutsCompanion.insert(
        userId: userId,
        syncId: _uuid(),
        date: date,
        startedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<Workout>> watchRecentWorkouts(String userId, {int limit = 10}) {
    return (select(workouts)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  Future<void> endWorkout(int workoutId) {
    return (update(workouts)..where((t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(endedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())),
    );
  }

  // ── WorkoutExercise queries ────────────────────────────────

  Future<WorkoutExercise> addExerciseToWorkout({
    required String userId,
    required int workoutId,
    required int exerciseId,
    required int orderIndex,
  }) {
    return into(workoutExercises).insertReturning(
      WorkoutExercisesCompanion.insert(
        userId: userId,
        syncId: _uuid(),
        workoutId: workoutId,
        exerciseId: exerciseId,
        orderIndex: orderIndex,
      ),
    );
  }

  Stream<List<WorkoutExercise>> watchWorkoutExercises(int workoutId) {
    return (select(workoutExercises)
          ..where((t) => t.workoutId.equals(workoutId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .watch();
  }

  // ── SetEntry queries ──────────────────────────────────────

  Future<SetEntry> addSet({
    required String userId,
    required int workoutExerciseId,
    required int setOrder,
    required double weightKg,
    required String unit,
    required int reps,
    bool isWarmup = false,
    double? rpe,
  }) {
    return into(setEntries).insertReturning(
      SetEntriesCompanion.insert(
        userId: userId,
        syncId: _uuid(),
        workoutExerciseId: workoutExerciseId,
        setOrder: setOrder,
        weightKg: weightKg,
        unit: Value(unit),
        reps: reps,
        isWarmup: Value(isWarmup),
        rpe: Value(rpe),
      ),
    );
  }

  Stream<List<SetEntry>> watchSets(int workoutExerciseId) {
    return (select(setEntries)
          ..where((t) => t.workoutExerciseId.equals(workoutExerciseId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.setOrder)]))
        .watch();
  }

  Future<void> updateSet(int setId, {double? weightKg, String? unit, int? reps, bool? isWarmup, double? rpe}) {
    return (update(setEntries)..where((t) => t.id.equals(setId))).write(
      SetEntriesCompanion(
        weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
        unit: unit != null ? Value(unit) : const Value.absent(),
        reps: reps != null ? Value(reps) : const Value.absent(),
        isWarmup: isWarmup != null ? Value(isWarmup) : const Value.absent(),
        rpe: rpe != null ? Value(rpe) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSet(int setId) {
    return (update(setEntries)..where((t) => t.id.equals(setId))).write(
      SetEntriesCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  // ── Exercise queries ──────────────────────────────────────

  Stream<List<Exercise>> watchExercises({String? group, String? query}) {
    return (select(exercises)
          ..where((t) {
            Expression<bool> cond = t.isArchived.equals(false);
            if (group != null) cond = cond & t.muscleGroup.equals(group);
            return cond;
          })
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((list) {
          if (query == null || query.isEmpty) return list;
          final q = query.trim();
          final isChosung = q.runes.every((c) => c >= 0x3131 && c <= 0x314E);
          return list.where((e) {
            if (isChosung) return e.chosung.contains(q);
            return e.name.contains(q) || e.chosung.contains(q);
          }).toList();
        });
  }

  Future<List<Exercise>> getExercisesByIds(List<int> ids) {
    return (select(exercises)..where((t) => t.id.isIn(ids))).get();
  }

  // ── Volume / Grass queries ─────────────────────────────────

  /// 일별 부위 볼륨 (워밍업 옵션 포함)
  Future<List<DailyGroupVolume>> getDailyGroupVolumes({
    required String userId,
    required DateTime from,
    required DateTime to,
    bool includeWarmup = false,
  }) async {
    final query = '''
      SELECT w.date, e.muscle_group, mg.color as group_color,
             SUM(s.weight_kg * s.reps) as volume_kg
      FROM set_entries s
      JOIN workout_exercises we ON we.id = s.workout_exercise_id
      JOIN workouts w ON w.id = we.workout_id
      JOIN exercises e ON e.id = we.exercise_id
      JOIN muscle_groups mg ON mg.name = e.muscle_group
      WHERE s.deleted_at IS NULL
        AND w.deleted_at IS NULL
        AND e.counts_volume = 1
        AND w.user_id = ?
        AND w.date >= ?
        AND w.date <= ?
        ${includeWarmup ? '' : 'AND s.is_warmup = 0'}
      GROUP BY w.date, e.muscle_group
      ORDER BY w.date ASC, volume_kg DESC
    ''';

    final rows = await customSelect(
      query,
      variables: [
        Variable.withString(userId),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
      ],
    ).get();

    return rows.map((r) => DailyGroupVolume(
      date: r.read<DateTime>('date'),
      muscleGroup: r.read<String>('muscle_group'),
      groupColor: r.read<String>('group_color'),
      volumeKg: r.read<double>('volume_kg'),
    )).toList();
  }

  // ── UserSettings queries ──────────────────────────────────

  Stream<UserSetting?> watchSettings(String userId) {
    return (select(userSettings)..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  Future<void> upsertSettings(UserSetting setting) {
    return into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(
        userId: setting.userId,
        defaultUnit: Value(setting.defaultUnit),
        warmupInVolume: Value(setting.warmupInVolume),
        showRpe: Value(setting.showRpe),
        timerAutoStart: Value(setting.timerAutoStart),
        timerSound: Value(setting.timerSound),
      ),
    );
  }

  // ── Previous set lookup ────────────────────────────────────

  Future<List<SetEntry>> getPreviousSets({
    required String userId,
    required int exerciseId,
    int limit = 5,
  }) async {
    final query = '''
      SELECT s.* FROM set_entries s
      JOIN workout_exercises we ON we.id = s.workout_exercise_id
      JOIN workouts w ON w.id = we.workout_id
      WHERE we.exercise_id = ?
        AND w.user_id = ?
        AND s.deleted_at IS NULL
        AND w.deleted_at IS NULL
      ORDER BY w.date DESC, s.set_order ASC
      LIMIT ?
    ''';

    final rows = await customSelect(
      query,
      variables: [
        Variable.withInt(exerciseId),
        Variable.withString(userId),
        Variable.withInt(limit),
      ],
    ).get();

    return rows.map((r) => SetEntry(
      id: r.read<int>('id'),
      userId: r.read<String>('user_id'),
      syncId: r.read<String>('sync_id'),
      workoutExerciseId: r.read<int>('workout_exercise_id'),
      setOrder: r.read<int>('set_order'),
      weightKg: r.read<double>('weight_kg'),
      unit: r.read<String>('unit'),
      reps: r.read<int>('reps'),
      isWarmup: r.read<bool>('is_warmup'),
      rpe: r.readNullable<double>('rpe'),
      createdAt: r.read<DateTime>('created_at'),
      updatedAt: r.read<DateTime>('updated_at'),
      deletedAt: r.readNullable<DateTime>('deleted_at'),
    )).toList();
  }
}

class DailyGroupVolume {
  final DateTime date;
  final String muscleGroup;
  final String groupColor;
  final double volumeKg;
  const DailyGroupVolume({
    required this.date,
    required this.muscleGroup,
    required this.groupColor,
    required this.volumeKg,
  });
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'volt.db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}

String _uuid() => generateUuid();
