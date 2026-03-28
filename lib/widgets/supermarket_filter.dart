import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SupermarketFilter extends StatelessWidget {
  const SupermarketFilter({super.key});

  static const Map<String, Color> supermarketColors = {
    'spar': Color(0xFF006633),
    'billa': Color(0xFFFFCC00),
    'hofer': Color(0xFF004A99),
    'penny': Color(0xFFCD1719),
  };

  static const Map<String, String> supermarketNames = {
    'spar': 'Spar',
    'billa': 'Billa',
    'hofer': 'Hofer',
    'penny': 'Penny',
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AppState.availableSupermarkets.map((supermarket) {
          final isSelected = appState.selectedSupermarkets.contains(supermarket);
          final color = supermarketColors[supermarket] ?? Colors.grey;
          final textColor = supermarket == 'billa' ? Colors.black : Colors.white;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                supermarketNames[supermarket] ?? supermarket,
                style: TextStyle(
                  color: isSelected ? textColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => appState.toggleSupermarket(supermarket),
              backgroundColor: Colors.grey[200],
              selectedColor: color,
              checkmarkColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}
