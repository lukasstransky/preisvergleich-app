import 'package:preisvergleich_app/models/price_alert.dart';
import 'package:preisvergleich_app/models/product.dart';

final testProducts = [
  Product(
    id: 'p1',
    name: 'Vollmilch 1L',
    price: 1.29,
    inPromotion: false,
    supermarket: 'billa',
    category: 'Milchprodukte',
    normalizedCategory: 'milchprodukte',
  ),
  Product(
    id: 'p2',
    name: 'Bio Vollmilch 1L',
    price: 1.59,
    originalPrice: 1.89,
    promotionText: '15% SALE',
    inPromotion: true,
    supermarket: 'spar',
    category: 'Milchprodukte',
    normalizedCategory: 'milchprodukte',
  ),
  Product(
    id: 'p3',
    name: 'Butter 250g',
    price: 2.49,
    inPromotion: false,
    supermarket: 'hofer',
    category: 'Milchprodukte',
    normalizedCategory: 'milchprodukte',
  ),
  Product(
    id: 'p4',
    name: 'Apfelsaft 1L',
    price: 0.99,
    originalPrice: 1.29,
    promotionText: '25% SALE',
    inPromotion: true,
    supermarket: 'penny',
    category: 'Getränke',
    normalizedCategory: 'getränke',
  ),
  Product(
    id: 'p5',
    name: 'Orangensaft 1L',
    price: 1.49,
    inPromotion: false,
    supermarket: 'lidl',
    category: 'Getränke',
    normalizedCategory: 'getränke',
  ),
];

final testProductAlert = PriceAlert(
  id: 'alert-1',
  productId: 'p1',
  productName: 'Vollmilch 1L',
  supermarket: 'billa',
  currentPrice: 1.29,
  alertType: AlertType.promotion,
  createdAt: DateTime(2025, 1, 1),
);

final testKeywordAlert = PriceAlert(
  id: 'alert-2',
  productId: '',
  productName: 'milch',
  supermarket: '',
  currentPrice: 0,
  alertType: AlertType.promotion,
  createdAt: DateTime(2025, 1, 2),
  scope: AlertScope.keyword,
  keyword: 'milch',
);
