import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// Floating translucent pill nav. Three slots: Home · center Add (solid square)
/// · Me. Active item is full-contrast; inactive is faint.
class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  /// 0 = Home, 1 = Me. (The centre Add button is an action, not a tab.)
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.nav),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: p.navBg,
              borderRadius: BorderRadius.circular(AppRadii.nav),
              border: Border.all(color: p.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  active: currentIndex == 0,
                  onTap: () => onSelect(0),
                ),
                const SizedBox(width: 26),
                _AddButton(onTap: onAdd),
                const SizedBox(width: 26),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Me',
                  active: currentIndex == 1,
                  onTap: () => onSelect(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.text : p.faint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontFamilyFallback: AppFonts.fallback,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: p.text,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.add_rounded, size: 24, color: p.bg),
      ),
    );
  }
}
