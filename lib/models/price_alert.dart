import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { promotion, targetPrice }

enum AlertScope { product, keyword }

class PriceAlert {
  final String id;
  final String productId;
  final String productName;
  final String supermarket;
  final String? imageUrl;
  final double currentPrice;
  final AlertType alertType;
  final double? targetPrice;
  final DateTime createdAt;
  final AlertScope scope;
  final String? keyword;
  final String? category;
  final bool conditionMet;

  const PriceAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.supermarket,
    this.imageUrl,
    required this.currentPrice,
    required this.alertType,
    this.targetPrice,
    required this.createdAt,
    this.scope = AlertScope.product,
    this.keyword,
    this.category,
    this.conditionMet = false,
  });

  bool get isKeywordAlert => scope == AlertScope.keyword;

  String get alertDescription {
    final cat = category != null ? ' · $category' : '';
    if (alertType == AlertType.promotion) return 'Bei Angebot$cat';
    return 'Unter €${targetPrice!.toStringAsFixed(2)}$cat';
  }

  factory PriceAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final scopeStr = data['scope'] as String?;
    return PriceAlert(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      supermarket: data['supermarket'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      currentPrice: (data['currentPrice'] as num? ?? 0).toDouble(),
      alertType: data['alertType'] == 'promotion'
          ? AlertType.promotion
          : AlertType.targetPrice,
      targetPrice: data['targetPrice'] != null
          ? (data['targetPrice'] as num).toDouble()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      scope: scopeStr == 'keyword' ? AlertScope.keyword : AlertScope.product,
      keyword: data['keyword'] as String?,
      category: data['category'] as String?,
      conditionMet: data['conditionMet'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore(String deviceToken) => {
        'deviceToken': deviceToken,
        'productId': productId,
        'productName': productName,
        'supermarket': supermarket,
        'imageUrl': imageUrl,
        'currentPrice': currentPrice,
        'alertType': alertType == AlertType.promotion ? 'promotion' : 'target_price',
        'targetPrice': targetPrice,
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
        'lastTriggered': null,
        'conditionMet': false,
        'scope': scope == AlertScope.keyword ? 'keyword' : 'product',
        'keyword': keyword,
        'category': category,
      };
}
