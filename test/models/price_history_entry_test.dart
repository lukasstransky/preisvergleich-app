import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/models/price_history_entry.dart';

void main() {
  group('PriceHistoryEntry.fromFirestore', () {
    test('parses double price and date string', () {
      final entry = PriceHistoryEntry.fromFirestore({
        'price': 1.49,
        'date': '2026-06-18',
      });
      expect(entry.price, 1.49);
      expect(entry.date, '2026-06-18');
    });

    test('parses int price as double', () {
      final entry = PriceHistoryEntry.fromFirestore({
        'price': 2,
        'date': '2026-06-19',
      });
      expect(entry.price, 2.0);
      expect(entry.price, isA<double>());
    });

    test('preserves full ISO date string', () {
      final entry = PriceHistoryEntry.fromFirestore({
        'price': 0.99,
        'date': '2026-01-01',
      });
      expect(entry.date, '2026-01-01');
    });

    test('handles zero price', () {
      final entry = PriceHistoryEntry.fromFirestore({
        'price': 0,
        'date': '2026-06-18',
      });
      expect(entry.price, 0.0);
    });

    test('handles large price values', () {
      final entry = PriceHistoryEntry.fromFirestore({
        'price': 99.99,
        'date': '2026-06-18',
      });
      expect(entry.price, closeTo(99.99, 0.001));
    });
  });

  group('PriceHistoryEntry constructor', () {
    test('stores price and date', () {
      const entry = PriceHistoryEntry(price: 3.45, date: '2026-06-20');
      expect(entry.price, 3.45);
      expect(entry.date, '2026-06-20');
    });
  });
}
