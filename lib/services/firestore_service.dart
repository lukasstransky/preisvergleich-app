import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> _collections = [
    'spar_products',
    'billa_products',
    'hofer_products',
    'penny_products',
  ];

  static const Map<String, String> collectionToSupermarket = {
    'spar_products': 'spar',
    'billa_products': 'billa',
    'hofer_products': 'hofer',
    'penny_products': 'penny',
  };

  Future<List<Product>> getAllProducts() async {
    List<Product> allProducts = [];

    for (String collection in _collections) {
      try {
        final snapshot = await _firestore.collection(collection).get();
        final products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        allProducts.addAll(products);
      } catch (e) {
        print('Error fetching $collection: $e');
      }
    }

    return allProducts;
  }

  Future<List<Product>> searchProductsOnServer(String query, {int limit = 50, Set<String>? supermarkets}) async {
    if (query.isEmpty) return [];
    
    List<Product> results = [];
    final collections = supermarkets != null && supermarkets.isNotEmpty
        ? supermarkets.map((s) => '${s.toLowerCase()}_products').where((c) => _collections.contains(c)).toList()
        : _collections;

    final limitPerCollection = (limit ~/ collections.length) + 10;

    for (String collection in collections) {
      try {
        final snapshot = await _firestore
            .collection(collection)
            .orderBy('name')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(limitPerCollection)
            .get();
        
        results.addAll(snapshot.docs.map((doc) => Product.fromFirestore(doc)));
        
        if (query.isNotEmpty && query[0].toUpperCase() != query[0]) {
          final capitalizedQuery = query[0].toUpperCase() + query.substring(1);
          final snapshotCapitalized = await _firestore
              .collection(collection)
              .orderBy('name')
              .startAt([capitalizedQuery])
              .endAt(['$capitalizedQuery\uf8ff'])
              .limit(limitPerCollection)
              .get();
          results.addAll(snapshotCapitalized.docs.map((doc) => Product.fromFirestore(doc)));
        }
      } catch (e) {
        print('Error searching $collection: $e');
      }
    }

    final uniqueResults = <String, Product>{};
    for (var p in results) {
      uniqueResults[p.id] = p;
    }
    
    final sortedResults = uniqueResults.values.toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    return sortedResults.take(limit).toList();
  }

  Future<List<Product>> getProductsFromSupermarkets(List<String> supermarkets, {int limit = 50}) async {
    List<Product> products = [];
    final limitPerCollection = limit ~/ supermarkets.length + 1;

    for (String supermarket in supermarkets) {
      final collection = '${supermarket.toLowerCase()}_products';
      if (_collections.contains(collection)) {
        try {
          final snapshot = await _firestore
              .collection(collection)
              .limit(limitPerCollection)
              .get();
          products.addAll(snapshot.docs.map((doc) => Product.fromFirestore(doc)));
        } catch (e) {
          print('Error fetching $collection: $e');
        }
      }
    }

    return products.take(limit).toList();
  }

  List<Product> searchProducts(List<Product> products, String query) {
    if (query.isEmpty) return products;
    
    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
             (product.brand?.toLowerCase().contains(lowerQuery) ?? false) ||
             (product.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<Product> filterBySupermarkets(List<Product> products, Set<String> selectedSupermarkets) {
    if (selectedSupermarkets.isEmpty) return products;
    
    return products.where((product) {
      return selectedSupermarkets.contains(product.supermarket.toLowerCase());
    }).toList();
  }

  List<Product> sortByPrice(List<Product> products, {bool ascending = true}) {
    final sorted = List<Product>.from(products);
    sorted.sort((a, b) => ascending 
        ? a.price.compareTo(b.price) 
        : b.price.compareTo(a.price));
    return sorted;
  }
}
