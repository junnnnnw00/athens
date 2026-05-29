import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// Horizontally scrollable pill filter chips. Selected = mint-soft bg + mint
/// text + bold, no border; default = neutral chip bg + muted + hairline.
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final label = options[i];
          final on = label == selected;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: on ? p.accentSoft : p.chip,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: on ? Colors.transparent : p.line),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontFamilyFallback: AppFonts.fallback,
                  fontSize: 13.5,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: on ? p.accentText : p.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
