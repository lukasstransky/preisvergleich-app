import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SupermarketFilter extends StatelessWidget {
  const SupermarketFilter({super.key});

  static const Map<String, Color> _colors = {
    'billa': Color(0xFFFFCC00),
    'spar': Color(0xFF007A3D),
    'hofer': Color(0xFF004A99),
    'penny': Color(0xFFCC1212),
    'lidl': Color(0xFF0050AA),
    'mpreis': Color(0xFFE30613),
  };

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
    final appState = context.watch<AppState>();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
        children: AppState.availableSupermarkets.map((s) {
          final isSelected = appState.selectedSupermarkets.contains(s);
          final color = _colors[s] ?? Colors.grey;
          final isDark = s == 'billa';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => appState.toggleSupermarket(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _names[s] ?? s,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.black87 : Colors.white)
                        : Colors.white.withValues(alpha: 0.9),
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
