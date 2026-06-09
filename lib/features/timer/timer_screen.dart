import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final int restSeconds;
  final String exerciseName;

  const TimerScreen({
    super.key,
    required this.restSeconds,
    required this.exerciseName,
  });

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late int _remaining;
  Timer? _timer;
  late AnimationController _ringController;
  final _player = AudioPlayer();

  static const _presets = [60, 90, 120, 150, 180];

  @override
  void initState() {
    super.initState();
    _totalSeconds = _snapPreset(widget.restSeconds);
    _remaining = _totalSeconds;
    _ringController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    )..forward();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        _onTimerEnd();
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _onTimerEnd() {
    final settings = ref.read(settingsNotifierProvider);
    if (settings.timerSound) {
      _player.play(AssetSource('sounds/timer_end.wav'));
    }
    if (!kIsWeb) {
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(pattern: [0, 300, 150, 300]);
      });
    }
    setState(() {});
  }

  void _adjust(int delta) {
    setState(() {
      _remaining = (_remaining + delta).clamp(0, 599);
      _totalSeconds = (_totalSeconds + delta).clamp(1, 599);
    });
    _ringController.duration = Duration(seconds: _totalSeconds);
  }

  void _setPreset(int seconds) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = seconds;
      _remaining = seconds;
    });
    _ringController.duration = Duration(seconds: _totalSeconds);
    _ringController.reset();
    _ringController.forward();
    _startTimer();
  }

  int _snapPreset(int s) {
    return _presets.reduce((a, b) => (a - s).abs() < (b - s).abs() ? a : b);
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? _remaining / _totalSeconds : 0.0;
    final isDone = _remaining <= 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('휴식 중', style: AppTextStyles.labelMd),
                      Text(widget.exerciseName, style: AppTextStyles.headingMd),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text('건너뛰기', style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Ring timer
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surfaceHigher,
                      color: isDone ? AppColors.success : AppColors.accent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(_remaining),
                        style: AppTextStyles.numLg.copyWith(
                          fontSize: 56,
                          color: isDone ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                      if (isDone)
                        Text('완료!', style: AppTextStyles.headingMd.copyWith(color: AppColors.success))
                      else
                        Text('남은 시간', style: AppTextStyles.labelMd),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ± adjustment
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AdjustButton(label: '-10', onTap: () => _adjust(-10)),
                const SizedBox(width: 8),
                _AdjustButton(label: '-5', onTap: () => _adjust(-5)),
                const SizedBox(width: 24),
                _AdjustButton(label: '+5', onTap: () => _adjust(5)),
                const SizedBox(width: 8),
                _AdjustButton(label: '+10', onTap: () => _adjust(10)),
              ],
            ),

            const SizedBox(height: 32),

            // Presets
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _presets.map((s) {
                final isActive = _totalSeconds == s;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _setPreset(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
                      ),
                      child: Text(
                        '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
                        style: AppTextStyles.numSm.copyWith(
                          color: isActive ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone ? AppColors.success : AppColors.surfaceHigh,
                  foregroundColor: isDone ? AppColors.bg : AppColors.textPrimary,
                ),
                child: Text(isDone ? '다음 세트로' : '타이머 종료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AdjustButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(label, style: AppTextStyles.numSm.copyWith(color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}
