import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class SupermarketFilter extends StatelessWidget {
  const SupermarketFilter({super.key});

  static const Map<String, String> _names = {
    'billa': 'Billa',
    'spar': 'Spar',
    'hofer': 'Hofer',
    'penny': 'Penny',
    'lidl': 'Lidl',
    'mpreis': 'MPreis',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final appState = context.watch<AppState>();
    final selected = appState.selectedSupermarkets;

    final visibleSupermarkets = AppState.availableSupermarkets;

    final allSelected = selected.length == visibleSupermarkets.length &&
        visibleSupermarkets.every((s) => selected.contains(s));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            children: [
              Opacity(
                opacity: 0.45,
                child: GestureDetector(
                  onTap: () => _showDataInfoSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
              _AllChip(allSelected: allSelected),
              const SizedBox(width: 8),
              ...visibleSupermarkets.map((s) {
                final isSelected = selected.contains(s);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SupermarketChip(
                    supermarket: s,
                    label: _names[s] ?? s,
                    color: AppColors.supermarket(s),
                    isSelected: isSelected,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showDataInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DataInfoSheet(),
    );
  }
}

// ── Data coverage info ────────────────────────────────────────────────────────

class _DataInfo {
  final String key;
  final String name;
  final Color color;
  final bool fullCatalog;
  final String description;

  const _DataInfo({
    required this.key,
    required this.name,
    required this.color,
    required this.fullCatalog,
    required this.description,
  });
}

final _dataInfos = [
  _DataInfo(
    key: 'billa',
    name: 'Billa',
    color: AppColors.supermarket('billa'),
    fullCatalog: true,
    description: 'Alle Produktkategorien inkl. Angebote',
  ),
  _DataInfo(
    key: 'spar',
    name: 'Spar',
    color: AppColors.supermarket('spar'),
    fullCatalog: true,
    description: 'Alle Produktkategorien inkl. Angebote',
  ),
  _DataInfo(
    key: 'mpreis',
    name: 'MPreis',
    color: AppColors.supermarket('mpreis'),
    fullCatalog: true,
    description: 'Lebensmittel & Getränke inkl. Aktionsprodukte',
  ),
  _DataInfo(
    key: 'penny',
    name: 'Penny',
    color: AppColors.supermarket('penny'),
    fullCatalog: false,
    description: 'Nur aktuelle Wochenangebote',
  ),
  _DataInfo(
    key: 'lidl',
    name: 'Lidl',
    color: AppColors.supermarket('lidl'),
    fullCatalog: false,
    description: 'Nur aktuelle Aktionsprodukte',
  ),
  _DataInfo(
    key: 'hofer',
    name: 'Hofer',
    color: AppColors.supermarket('hofer'),
    fullCatalog: false,
    description: 'Angebotsflugblätter & Tiefpreis-Aktionen',
  ),
];

class _DataInfoSheet extends StatelessWidget {
  const _DataInfoSheet();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.surfaceHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verfügbare Daten',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Je nach Supermarkt sind unterschiedliche Produktdaten verfügbar.',
            style: TextStyle(
                fontSize: 13, color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          const _SectionLabel(label: 'Vollsortiment'),
          const SizedBox(height: 8),
          ..._dataInfos
              .where((d) => d.fullCatalog)
              .map((d) => _DataInfoRow(info: d)),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Nur Angebote'),
          const SizedBox(height: 8),
          ..._dataInfos
              .where((d) => !d.fullCatalog)
              .map((d) => _DataInfoRow(info: d)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 14, color: c.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bei Supermärkten mit Vollsortiment findest du auch Produkte ohne aktive Angebote.',
                    style: TextStyle(
                        fontSize: 12,
                        color: c.textSecondary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: c.textTertiary,
      ),
    );
  }
}

class _DataInfoRow extends StatelessWidget {
  final _DataInfo info;
  const _DataInfoRow({required this.info});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: info.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 54,
            child: Text(
              info.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              info.description,
              style: TextStyle(
                  fontSize: 13, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chips ─────────────────────────────────────────────────────────────────────

class _AllChip extends StatelessWidget {
  final bool allSelected;
  const _AllChip({required this.allSelected});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => context.read<AppState>().selectAllSupermarkets(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: allSelected ? c.primary : c.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: allSelected ? c.primary : c.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allSelected) ...[
              Icon(Icons.check_rounded,
                  size: 13, color: c.onPrimary),
              const SizedBox(width: 4),
            ],
            Text(
              'Alle',
              style: TextStyle(
                color: allSelected
                    ? c.onPrimary
                    : c.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupermarketChip extends StatelessWidget {
  final String supermarket;
  final String label;
  final Color color;
  final bool isSelected;

  const _SupermarketChip({
    required this.supermarket,
    required this.label,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => context.read<AppState>().toggleSupermarket(supermarket),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : c.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : c.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? color : c.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? c.textPrimary
                    : c.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_rounded, size: 13, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
