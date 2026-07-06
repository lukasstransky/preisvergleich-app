import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/price_history_entry.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class PriceHistoryChart extends StatefulWidget {
  final Product product;

  /// Overrides the default Firestore loader — primarily for testing.
  final Future<List<PriceHistoryEntry>> Function(String supermarket, String id)? loader;

  const PriceHistoryChart({
    super.key,
    required this.product,
    this.loader,
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  List<PriceHistoryEntry>? _history;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final load = widget.loader ?? FirestoreService().getPriceHistory;
      final entries =
          await load(widget.product.supermarket, widget.product.id);
      if (mounted) setState(() => _history = entries);
    } catch (_) {
      if (mounted) setState(() => _history = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_history == null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: c.primary),
        ),
      );
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final allEntries = List<PriceHistoryEntry>.from(_history!);
    if (allEntries.isEmpty || allEntries.last.date != today) {
      allEntries.add(
          PriceHistoryEntry(price: widget.product.price, date: today));
    }

    if (allEntries.length < 2) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.show_chart_rounded, size: 16, color: c.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Wir beobachten den Preis – der Verlauf erscheint, sobald er sich ändert.',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final prices = allEntries.map((e) => e.price).toList();
    final minP = prices.reduce(min);
    final maxP = prices.reduce(max);
    final range = maxP - minP;
    final yPad = range > 0 ? range * 0.25 : 0.5;
    final yMin = max(0.0, minP - yPad);
    final yMax = maxP + yPad;
    final yInterval = range > 0 ? (yMax - yMin) / 3 : 1.0;

    final spots = [
      for (int i = 0; i < allEntries.length; i++)
        FlSpot(i.toDouble(), allEntries[i].price),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Text(
                'Preisverlauf',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: yMin,
                maxY: yMax,
                clipData: const FlClipData.all(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    isStepLineChart: true,
                    color: c.primary,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.x == spots.last.x,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 5,
                        color: c.primary,
                        strokeWidth: 2,
                        strokeColor: c.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: c.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '€${value.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 10, color: c.textSecondary),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if (idx < 0 || idx >= allEntries.length) {
                          return const SizedBox.shrink();
                        }
                        final isFirst = idx == 0;
                        final isLast = idx == allEntries.length - 1;
                        if (!isFirst && !isLast) return const SizedBox.shrink();
                        final parts = allEntries[idx].date.split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${parts[2]}.${parts[1]}.',
                            style: TextStyle(
                                fontSize: 10, color: c.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: c.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) =>
                        touchedSpots.map((s) {
                      final idx = s.spotIndex;
                      final parts = allEntries[idx].date.split('-');
                      final dateLabel = '${parts[2]}.${parts[1]}.';
                      return LineTooltipItem(
                        '€${s.y.toStringAsFixed(2)}\n',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                        children: [
                          TextSpan(
                            text: dateLabel,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.normal,
                                fontSize: 11),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
