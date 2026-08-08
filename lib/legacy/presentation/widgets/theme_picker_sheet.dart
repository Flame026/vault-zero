import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_preset.dart';
import '../../../core/theme/theme_provider.dart';

class ThemePickerSheet extends ConsumerWidget {
  const ThemePickerSheet({super.key});

  Widget _themePreviewDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(190),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final selectedThemePreset = ref.watch(themeProvider).preset;

    return SizedBox(
      height: screenHeight * 0.78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Theme Colour',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your choice works in both light and dark mode.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: ThemePreset.values.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final preset = ThemePreset.values[index];
                  final isSelected = preset == selectedThemePreset;

                  final previewLight = Color.lerp(preset.seedColor, Colors.white, 0.62)!;
                  final previewDark = Color.lerp(preset.seedColor, Colors.black, 0.34)!;

                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: isSelected
                        ? colorScheme.primaryContainer.withAlpha(150)
                        : colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        ref.read(themeProvider.notifier).changePreset(preset);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(left: 0, child: _themePreviewDot(previewLight, 24)),
                                  Positioned(right: 0, child: _themePreviewDot(previewDark, 24)),
                                  _themePreviewDot(preset.seedColor, 30),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.label,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    preset.description,
                                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, size: 17, color: colorScheme.onPrimary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
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
    );
  }
}
