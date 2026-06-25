import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/algolia_service.dart';
import '../theme/app_colors.dart';

class FilterSection extends StatelessWidget {
  const FilterSection({super.key});

  static const _chipHeight = 32.0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final appState = context.watch<AppState>();
    final hasCategories = appState.availableCategories.isNotEmpty;

    return ColoredBox(
      color: c.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Sort + Angebote
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                _SortChip(
                  label: 'Relevanz',
                  icon: Icons.auto_awesome_rounded,
                  selected: appState.sortOrder == SortOrder.relevance,
                  onTap: () => appState.setSortOrder(SortOrder.relevance),
                ),
                const SizedBox(width: 6),
                _SortChip(
                  label: '€/kg',
                  icon: Icons.straighten_rounded,
                  selected: appState.sortOrder == SortOrder.unitPrice,
                  onTap: () => appState.setSortOrder(SortOrder.unitPrice),
                ),
                Container(
                  width: 1,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: c.border,
                ),
                _ActionChip(
                  label: 'Angebote',
                  icon: Icons.local_offer_rounded,
                  active: appState.onlyPromotions,
                  activeColor: c.danger,
                  onTap: appState.toggleOnlyPromotions,
                ),
              ],
            ),
          ),
          // Row 2: Categories (only when available)
          if (hasCategories) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: _chipHeight + 2,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                children: [
                  _CategoryChip(
                    label: 'Alle',
                    count: null,
                    selected: appState.selectedCategory == null,
                    onTap: () => appState.setCategory(null),
                  ),
                  const SizedBox(width: 6),
                  ...appState.availableCategories.map((cat) {
                    final count = appState.categoryCounts[cat] ?? 0;
                    final isDominant = cat == appState.dominantCategory &&
                        appState.selectedCategory == null;
                    final isSelected = appState.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _CategoryChip(
                        label: cat,
                        count: count,
                        selected: isSelected,
                        dominant: isDominant,
                        onTap: () =>
                            appState.setCategory(isSelected ? null : cat),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? c.onPrimary : c.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? c.onPrimary : c.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : c.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: active ? c.onPrimary : c.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? c.onPrimary : c.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final bool dominant;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.count,
    required this.selected,
    this.dominant = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? c.primary
              : dominant
                  ? c.primary.withValues(alpha: 0.08)
                  : c.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: dominant && !selected
              ? Border.all(
                  color: c.primary.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dominant && !selected) ...[
              Icon(Icons.trending_up_rounded,
                  size: 12, color: c.primary),
              const SizedBox(width: 4),
            ],
            Text(
              count != null ? '$label · $count' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? c.onPrimary
                    : dominant
                        ? c.primary
                        : c.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
