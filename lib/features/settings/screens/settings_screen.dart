import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _SectionHeader('단위'),
          _SettingTile(
            title: '기본 무게 단위',
            subtitle: settings.defaultUnit.toUpperCase(),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'kg', label: Text('kg')),
                ButtonSegment(value: 'lb', label: Text('lb')),
              ],
              selected: {settings.defaultUnit},
              onSelectionChanged: (v) => notifier.update(defaultUnit: v.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return AppColors.accent;
                  return AppColors.surfaceHigh;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return AppColors.bg;
                  return AppColors.textSecondary;
                }),
              ),
            ),
          ),

          _SectionHeader('볼륨'),
          SwitchListTile(
            title: Text('워밍업 볼륨 포함', style: AppTextStyles.bodyMd),
            subtitle: Text('워밍업 세트를 볼륨 집계에 포함', style: AppTextStyles.bodySm),
            value: settings.warmupInVolume,
            onChanged: (v) => notifier.update(warmupInVolume: v),
            activeColor: AppColors.accent,
          ),

          _SectionHeader('표시'),
          SwitchListTile(
            title: Text('RPE 표시', style: AppTextStyles.bodyMd),
            subtitle: Text('세트 입력 시 RPE 옵션 노출', style: AppTextStyles.bodySm),
            value: settings.showRpe,
            onChanged: (v) => notifier.update(showRpe: v),
            activeColor: AppColors.accent,
          ),

          _SectionHeader('타이머'),
          SwitchListTile(
            title: Text('타이머 자동 시작', style: AppTextStyles.bodyMd),
            subtitle: Text('세트 완료 시 자동으로 휴식 타이머 시작', style: AppTextStyles.bodySm),
            value: settings.timerAutoStart,
            onChanged: (v) => notifier.update(timerAutoStart: v),
            activeColor: AppColors.accent,
          ),
          SwitchListTile(
            title: Text('타이머 사운드', style: AppTextStyles.bodyMd),
            subtitle: Text('휴식 종료 시 알림음 재생', style: AppTextStyles.bodySm),
            value: settings.timerSound,
            onChanged: (v) => notifier.update(timerSound: v),
            activeColor: AppColors.accent,
          ),

          _SectionHeader('데이터'),
          ListTile(
            title: Text('CSV 내보내기', style: AppTextStyles.bodyMd),
            leading: const Icon(Icons.download_outlined),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV 내보내기 준비 중...')),
              );
            },
          ),
          ListTile(
            title: Text('JSON 내보내기', style: AppTextStyles.bodyMd),
            leading: const Icon(Icons.code_outlined),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON 내보내기 준비 중...')),
              );
            },
          ),

          _SectionHeader('정보'),
          ListTile(
            title: Text('버전', style: AppTextStyles.bodyMd),
            trailing: Text('1.0.0', style: AppTextStyles.bodySm),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(color: AppColors.accent),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget trailing;

  const _SettingTile({required this.title, this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTextStyles.bodyMd),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.bodySm) : null,
      trailing: trailing,
    );
  }
}
