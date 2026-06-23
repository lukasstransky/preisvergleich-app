import 'package:flutter_test/flutter_test.dart';
import 'package:preisvergleich_app/models/product.dart';

const _base = {
  'id': 'p1',
  'name': 'Milch',
  'price': 1.29,
  'inPromotion': false,
  'supermarket': 'spar',
};

void main() {
  group('Product.fromJson', () {
    test('parses required fields', () {
      final p = Product.fromJson(_base);
      expect(p.id, 'p1');
      expect(p.name, 'Milch');
      expect(p.price, 1.29);
      expect(p.inPromotion, false);
      expect(p.supermarket, 'spar');
    });

    test('uses defaults for missing fields', () {
      final p = Product.fromJson({});
      expect(p.id, '');
      expect(p.name, '');
      expect(p.price, 0.0);
      expect(p.inPromotion, false);
      expect(p.supermarket, '');
    });

    test('parses optional fields', () {
      final p = Product.fromJson({
        ..._base,
        'originalPrice': 1.99,
        'promotionText': '20% Rabatt',
        'unitPrice': 1.29,
        'unitLabel': 'l',
        'category': 'Milchprodukte',
        'brand': 'Bergbauer',
        'sku': 'SKU123',
        'imageUrl': 'https://example.com/img.jpg',
      });
      expect(p.originalPrice, 1.99);
      expect(p.promotionText, '20% Rabatt');
      expect(p.unitPrice, 1.29);
      expect(p.unitLabel, 'l');
      expect(p.category, 'Milchprodukte');
      expect(p.brand, 'Bergbauer');
      expect(p.sku, 'SKU123');
      expect(p.imageUrl, 'https://example.com/img.jpg');
    });

    test('parses productUrl, offerStart, offerEnd', () {
      final p = Product.fromJson({
        ..._base,
        'productUrl': 'https://www.spar.at/produkt/milch',
        'offerStart': '2026-06-23',
        'offerEnd': '2026-06-30',
      });
      expect(p.productUrl, 'https://www.spar.at/produkt/milch');
      expect(p.offerStart, '2026-06-23');
      expect(p.offerEnd, '2026-06-30');
    });

    test('productUrl, offerStart, offerEnd default to null', () {
      final p = Product.fromJson(_base);
      expect(p.productUrl, isNull);
      expect(p.offerStart, isNull);
      expect(p.offerEnd, isNull);
    });
  });

  group('Product.toJson / fromJson round-trip', () {
    test('preserves all fields', () {
      final original = Product(
        id: 'p2',
        name: 'Butter',
        price: 2.49,
        originalPrice: 2.99,
        promotionText: '20% Rabatt',
        unitPrice: 4.98,
        unitLabel: 'kg',
        category: 'Molkerei',
        brand: 'Bergbauer',
        sku: 'SKU456',
        inPromotion: true,
        imageUrl: 'https://example.com/butter.jpg',
        supermarket: 'billa',
        productUrl: 'https://www.billa.at/produkte/butter',
        offerStart: '2026-06-23',
        offerEnd: '2026-06-30',
      );
      final rt = Product.fromJson(original.toJson());
      expect(rt.id, original.id);
      expect(rt.name, original.name);
      expect(rt.price, original.price);
      expect(rt.originalPrice, original.originalPrice);
      expect(rt.promotionText, original.promotionText);
      expect(rt.unitPrice, original.unitPrice);
      expect(rt.unitLabel, original.unitLabel);
      expect(rt.category, original.category);
      expect(rt.brand, original.brand);
      expect(rt.sku, original.sku);
      expect(rt.inPromotion, original.inPromotion);
      expect(rt.imageUrl, original.imageUrl);
      expect(rt.supermarket, original.supermarket);
      expect(rt.productUrl, original.productUrl);
      expect(rt.offerStart, original.offerStart);
      expect(rt.offerEnd, original.offerEnd);
    });

    test('null optional fields survive round-trip', () {
      final p = Product.fromJson(_base);
      final rt = Product.fromJson(p.toJson());
      expect(rt.originalPrice, isNull);
      expect(rt.promotionText, isNull);
      expect(rt.unitPrice, isNull);
      expect(rt.unitLabel, isNull);
      expect(rt.imageUrl, isNull);
      expect(rt.productUrl, isNull);
      expect(rt.offerStart, isNull);
      expect(rt.offerEnd, isNull);
    });
  });

  group('Product.formattedPrice', () {
    test('formats with two decimal places', () {
      expect(Product.fromJson({..._base, 'price': 1.5}).formattedPrice, '€1.50');
      expect(Product.fromJson({..._base, 'price': 10.0}).formattedPrice, '€10.00');
      expect(Product.fromJson({..._base, 'price': 0.99}).formattedPrice, '€0.99');
    });
  });

  group('Product.formattedOriginalPrice', () {
    test('is null when originalPrice is absent', () {
      expect(Product.fromJson(_base).formattedOriginalPrice, isNull);
    });

    test('formats correctly when present', () {
      final p = Product.fromJson({..._base, 'originalPrice': 2.0});
      expect(p.formattedOriginalPrice, '€2.00');
    });
  });

  group('Product.formattedUnitPrice', () {
    test('is null when both unitPrice and unitLabel are absent', () {
      expect(Product.fromJson(_base).formattedUnitPrice, isNull);
    });

    test('is null when only unitPrice is present', () {
      final p = Product.fromJson({..._base, 'unitPrice': 1.5});
      expect(p.formattedUnitPrice, isNull);
    });

    test('is null when only unitLabel is present', () {
      final p = Product(
        id: 'p',
        name: 'n',
        price: 1.0,
        inPromotion: false,
        supermarket: 'spar',
        unitLabel: 'kg',
      );
      expect(p.formattedUnitPrice, isNull);
    });

    test('formats correctly when both are present', () {
      final p = Product(
        id: 'p',
        name: 'n',
        price: 1.0,
        inPromotion: false,
        supermarket: 'spar',
        unitPrice: 2.50,
        unitLabel: 'kg',
      );
      expect(p.formattedUnitPrice, '€2.50/kg');
    });
  });

  group('Product.formattedOfferPeriod', () {
    test('is null when neither offerStart nor offerEnd is set', () {
      final p = Product.fromJson(_base);
      expect(p.formattedOfferPeriod, isNull);
    });

    test('shows "bis <date>" when only offerEnd is set', () {
      final p = Product.fromJson({..._base, 'offerEnd': '2026-06-30'});
      expect(p.formattedOfferPeriod, 'bis 30. Jun');
    });

    test('shows "ab <date>" when only offerStart is set', () {
      final p = Product.fromJson({..._base, 'offerStart': '2026-06-23'});
      expect(p.formattedOfferPeriod, 'ab 23. Jun');
    });

    test('shows "<start> – <end>" when both are set', () {
      final p = Product.fromJson({
        ..._base,
        'offerStart': '2026-06-23',
        'offerEnd': '2026-06-30',
      });
      expect(p.formattedOfferPeriod, '23. Jun – 30. Jun');
    });

    test('shows correct month names', () {
      final cases = {
        '2026-01-05': '5. Jan',
        '2026-02-14': '14. Feb',
        '2026-03-01': '1. Mär',
        '2026-04-10': '10. Apr',
        '2026-05-20': '20. Mai',
        '2026-07-04': '4. Jul',
        '2026-08-15': '15. Aug',
        '2026-09-22': '22. Sep',
        '2026-10-31': '31. Okt',
        '2026-11-11': '11. Nov',
        '2026-12-24': '24. Dez',
      };
      for (final entry in cases.entries) {
        final p = Product.fromJson({..._base, 'offerEnd': entry.key});
        expect(p.formattedOfferPeriod, 'bis ${entry.value}',
            reason: 'failed for date ${entry.key}');
      }
    });

    test('is null when offerEnd is an invalid date string', () {
      final p = Product.fromJson({..._base, 'offerEnd': 'not-a-date'});
      expect(p.formattedOfferPeriod, isNull);
    });
  });

  group('Product.supermarketDisplayName', () {
    for (final entry in {
      'spar': 'Spar',
      'SPAR': 'Spar',
      'billa': 'Billa',
      'hofer': 'Hofer',
      'penny': 'Penny',
      'lidl': 'Lidl',
      'mpreis': 'MPreis',
      'unknown': 'unknown',
    }.entries) {
      test('maps "${entry.key}" → "${entry.value}"', () {
        final p = Product.fromJson({..._base, 'supermarket': entry.key});
        expect(p.supermarketDisplayName, entry.value);
      });
    }
  });
}
