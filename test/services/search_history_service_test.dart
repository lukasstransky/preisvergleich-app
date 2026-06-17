import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preisvergleich_app/services/search_history_service.dart';

void main() {
  late SearchHistoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SearchHistoryService();
  });

  group('SearchHistoryService', () {
    test('getHistory returns empty list initially', () async {
      expect(await service.getHistory(), isEmpty);
    });

    test('addSearch adds a single entry', () async {
      await service.addSearch('Milch');
      expect(await service.getHistory(), ['Milch']);
    });

    test('addSearch inserts at the front', () async {
      await service.addSearch('Milch');
      await service.addSearch('Butter');
      expect(await service.getHistory(), ['Butter', 'Milch']);
    });

    test('addSearch deduplicates by moving existing entry to front', () async {
      await service.addSearch('Milch');
      await service.addSearch('Butter');
      await service.addSearch('Milch');
      final history = await service.getHistory();
      expect(history, ['Milch', 'Butter']);
      expect(history.length, 2);
    });

    test('addSearch ignores empty string', () async {
      await service.addSearch('');
      expect(await service.getHistory(), isEmpty);
    });

    test('addSearch ignores whitespace-only string', () async {
      await service.addSearch('   ');
      expect(await service.getHistory(), isEmpty);
    });

    test('addSearch trims whitespace before storing', () async {
      await service.addSearch('  Milch  ');
      expect(await service.getHistory(), ['Milch']);
    });

    test('addSearch limits history to 8 entries', () async {
      for (var i = 1; i <= 10; i++) {
        await service.addSearch('query$i');
      }
      final history = await service.getHistory();
      expect(history.length, 8);
      expect(history.first, 'query10');
      expect(history.contains('query1'), false);
      expect(history.contains('query2'), false);
    });

    test('removeSearch removes the entry', () async {
      await service.addSearch('Milch');
      await service.addSearch('Butter');
      await service.removeSearch('Milch');
      expect(await service.getHistory(), ['Butter']);
    });

    test('removeSearch is a no-op for non-existing entry', () async {
      await service.addSearch('Milch');
      await service.removeSearch('Brot');
      expect(await service.getHistory(), ['Milch']);
    });

    test('clearHistory empties the list', () async {
      await service.addSearch('Milch');
      await service.addSearch('Butter');
      await service.clearHistory();
      expect(await service.getHistory(), isEmpty);
    });

    test('getHistory after clearHistory returns empty list', () async {
      await service.clearHistory();
      expect(await service.getHistory(), isEmpty);
    });
  });
}
