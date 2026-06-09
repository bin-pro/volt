import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MuscleGroupSelectScreen extends StatefulWidget {
  const MuscleGroupSelectScreen({super.key});

  @override
  State<MuscleGroupSelectScreen> createState() => _MuscleGroupSelectScreenState();
}

class _MuscleGroupSelectScreenState extends State<MuscleGroupSelectScreen> {
  final Set<String> _selected = {};

  static const _groups = [
    ('가슴', 'assets/images/muscle_groups/chest.jpg'),
    ('등', 'assets/images/muscle_groups/back.jpg'),
    ('어깨', 'assets/images/muscle_groups/shoulder.jpg'),
    ('팔', 'assets/images/muscle_groups/arm.jpg'),
    ('하체', 'assets/images/muscle_groups/leg.jpg'),
    ('복근', 'assets/images/muscle_groups/abs.jpg'),
    ('유산소', 'assets/images/muscle_groups/cardio.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부위 선택'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘 어디 운동할까요?', style: AppTextStyles.displaySm),
            const SizedBox(height: 8),
            Text('여러 부위를 동시에 선택할 수 있습니다', style: AppTextStyles.bodySm),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemCount: _groups.length,
                itemBuilder: (context, i) {
                  final (name, imagePath) = _groups[i];
                  final isSelected = _selected.contains(name);
                  final color = AppColors.muscleGroupColor(name);
                  return GestureDetector(
                    onTap: () => setState(() {
                      isSelected ? _selected.remove(name) : _selected.add(name);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            // 배경 이미지 (DecorationImage)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(imagePath),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withValues(alpha: isSelected ? 0.25 : 0.40),
                                      BlendMode.darken,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 선택 시 부위 색상 틴트
                            if (isSelected)
                              Positioned.fill(
                                child: ColoredBox(
                                  color: color.withValues(alpha: 0.25),
                                ),
                              ),
                            // 이름 + 체크 뱃지
                            Positioned(
                              left: 14,
                              bottom: 14,
                              right: 14,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: AppTextStyles.headingMd.copyWith(
                                        color: Colors.white,
                                        shadows: [
                                          const Shadow(color: Colors.black54, blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      child: const Icon(Icons.check, size: 14, color: Colors.black),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _selected.isEmpty
                ? null
                : () => context.push('/session/exercises', extra: _selected.toList()),
            child: Text(_selected.isEmpty ? '부위를 선택하세요' : '종목 선택 (${_selected.length}개 부위)'),
          ),
        ),
      ),
    );
  }
}
