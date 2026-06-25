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
    final appState = context.watch<AppState>();
    final hasCategories = appState.availableCategories.isNotEmpty;

    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Sort + Angebote
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
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
                  color: AppColors.border,
                ),
                _ActionChip(
                  label: 'Angebote',
                  icon: Icons.local_offer_rounded,
                  active: appState.onlyPromotions,
                  activeColor: AppColors.danger,
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
          const SizedBox(height: 10),
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

  static const _primary = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: active ? AppColors.onPrimary : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.onPrimary : AppColors.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<String> categories;
  final Map<String, int> categoryCounts;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.categoryCounts,
    required this.selectedCategory,
    required this.onChanged,
  });

  static const _primary = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCategory != null;

    return GestureDetector(
      onTap: () => _openSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasSelection ? _primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_rounded,
              size: 13,
              color: hasSelection ? AppColors.onPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              hasSelection
                  ? '$selectedCategory · ${categoryCounts[selectedCategory] ?? 0}'
                  : 'Kategorie',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasSelection ? AppColors.onPrimary : AppColors.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: hasSelection ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        categories: categories,
        categoryCounts: categoryCounts,
        selectedCategory: selectedCategory,
        onChanged: onChanged,
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  final List<String> categories;
  final Map<String, int> categoryCounts;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategorySheet({
    required this.categories,
    required this.categoryCounts,
    required this.selectedCategory,
    required this.onChanged,
  });

  static const _primary = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Kategorie',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (selectedCategory != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      onChanged(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Zurücksetzen',
                        style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                _SheetOption(
                  label: 'Alle Kategorien',
                  count: null,
                  selected: selectedCategory == null,
                  onTap: () {
                    onChanged(null);
                    Navigator.pop(context);
                  },
                ),
                ...categories.map((cat) => _SheetOption(
                      label: cat,
                      count: categoryCounts[cat] ?? 0,
                      selected: selectedCategory == cat,
                      onTap: () {
                        onChanged(selectedCategory == cat ? null : cat);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  static const _primary = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                count != null ? '$label · $count' : label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? _primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 18, color: _primary),
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

  static const _primary = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? _primary
              : dominant
                  ? _primary.withValues(alpha: 0.08)
                  : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: dominant && !selected
              ? Border.all(
                  color: _primary.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dominant && !selected) ...[
              Icon(Icons.trending_up_rounded,
                  size: 12, color: _primary),
              const SizedBox(width: 4),
            ],
            Text(
              count != null ? '$label · $count' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.onPrimary
                    : dominant
                        ? _primary
                        : AppColors.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

