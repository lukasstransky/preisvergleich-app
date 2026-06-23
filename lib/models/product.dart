import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final String? promotionText;
  final double? unitPrice;
  final String? unitLabel;
  final String? category;
  final String? brand;
  final String? sku;
  final bool inPromotion;
  final String? imageUrl;
  final String supermarket;
  final String? normalizedCategory;
  final int? nameLength;
  final String? productUrl;
  final String? offerStart;
  final String? offerEnd;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.promotionText,
    this.unitPrice,
    this.unitLabel,
    this.category,
    this.brand,
    this.sku,
    required this.inPromotion,
    this.imageUrl,
    required this.supermarket,
    this.normalizedCategory,
    this.nameLength,
    this.productUrl,
    this.offerStart,
    this.offerEnd,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: data['originalPrice']?.toDouble(),
      promotionText: data['promotionText'],
      unitPrice: data['unitPrice']?.toDouble(),
      unitLabel: data['unitLabel'],
      category: data['category'],
      brand: data['brand'],
      sku: data['sku'],
      inPromotion: data['inPromotion'] ?? false,
      imageUrl: data['imageUrl'],
      supermarket: data['supermarket'] ?? '',
      normalizedCategory: data['normalizedCategory'],
      nameLength: data['nameLength'],
      productUrl: data['productUrl'],
      offerStart: data['offerStart'],
      offerEnd: data['offerEnd'],
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      promotionText: json['promotionText'],
      unitPrice: json['unitPrice']?.toDouble(),
      unitLabel: json['unitLabel'],
      category: json['category'],
      brand: json['brand'],
      sku: json['sku'],
      inPromotion: json['inPromotion'] ?? false,
      imageUrl: json['imageUrl'],
      supermarket: json['supermarket'] ?? '',
      productUrl: json['productUrl'],
      offerStart: json['offerStart'],
      offerEnd: json['offerEnd'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'promotionText': promotionText,
      'unitPrice': unitPrice,
      'unitLabel': unitLabel,
      'category': category,
      'brand': brand,
      'sku': sku,
      'inPromotion': inPromotion,
      'imageUrl': imageUrl,
      'supermarket': supermarket,
      'productUrl': productUrl,
      'offerStart': offerStart,
      'offerEnd': offerEnd,
    };
  }

  String get formattedPrice => '€${price.toStringAsFixed(2)}';
  
  String? get formattedOriginalPrice => 
      originalPrice != null ? '€${originalPrice!.toStringAsFixed(2)}' : null;
  
  String? get formattedUnitPrice => 
      unitPrice != null && unitLabel != null 
          ? '€${unitPrice!.toStringAsFixed(2)}/$unitLabel' 
          : null;

  String? get formattedOfferPeriod {
    final start = _parseDate(offerStart);
    final end = _parseDate(offerEnd);
    if (start == null && end == null) return null;
    if (start != null && end != null) {
      return '${_formatDate(start)} – ${_formatDate(end)}';
    }
    if (end != null) return 'bis ${_formatDate(end)}';
    return 'ab ${_formatDate(start!)}';
  }

  static DateTime? _parseDate(String? s) {
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];
    return '${d.day}. ${months[d.month - 1]}';
  }

  String get supermarketDisplayName {
    switch (supermarket.toLowerCase()) {
      case 'spar':
        return 'Spar';
      case 'billa':
        return 'Billa';
      case 'hofer':
        return 'Hofer';
      case 'penny':
        return 'Penny';
      case 'lidl':
        return 'Lidl';
      case 'mpreis':
        return 'MPreis';
      default:
        return supermarket;
    }
  }
}
