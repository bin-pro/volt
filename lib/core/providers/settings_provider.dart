import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

class AppSettings {
  final String defaultUnit;
  final bool warmupInVolume;
  final bool showRpe;
  final bool timerAutoStart;
  final bool timerSound;

  const AppSettings({
    this.defaultUnit = 'kg',
    this.warmupInVolume = false,
    this.showRpe = true,
    this.timerAutoStart = true,
    this.timerSound = true,
  });

  AppSettings copyWith({
    String? defaultUnit,
    bool? warmupInVolume,
    bool? showRpe,
    bool? timerAutoStart,
    bool? timerSound,
  }) =>
      AppSettings(
        defaultUnit: defaultUnit ?? this.defaultUnit,
        warmupInVolume: warmupInVolume ?? this.warmupInVolume,
        showRpe: showRpe ?? this.showRpe,
        timerAutoStart: timerAutoStart ?? this.timerAutoStart,
        timerSound: timerSound ?? this.timerSound,
      );

  static AppSettings fromRow(UserSetting row) => AppSettings(
        defaultUnit: row.defaultUnit,
        warmupInVolume: row.warmupInVolume,
        showRpe: row.showRpe,
        timerAutoStart: row.timerAutoStart,
        timerSound: row.timerSound,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    // Async load from DB then update state
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final row = await db.watchSettings(kLocalUserId).first;
    if (row != null) {
      state = AppSettings.fromRow(row);
    } else {
      // Insert defaults
      await _persist(state);
    }
  }

  Future<void> _persist(AppSettings s) async {
    final db = ref.read(databaseProvider);
    await db.upsertSettings(UserSetting(
      userId: kLocalUserId,
      defaultUnit: s.defaultUnit,
      warmupInVolume: s.warmupInVolume,
      showRpe: s.showRpe,
      timerAutoStart: s.timerAutoStart,
      timerSound: s.timerSound,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> update({
    String? defaultUnit,
    bool? warmupInVolume,
    bool? showRpe,
    bool? timerAutoStart,
    bool? timerSound,
  }) async {
    state = state.copyWith(
      defaultUnit: defaultUnit,
      warmupInVolume: warmupInVolume,
      showRpe: showRpe,
      timerAutoStart: timerAutoStart,
      timerSound: timerSound,
    );
    await _persist(state);
  }
}

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
