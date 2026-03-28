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

  Future<List<Product>> getProductsFromSupermarkets(List<String> supermarkets) async {
    List<Product> products = [];

    for (String supermarket in supermarkets) {
      final collection = '${supermarket.toLowerCase()}_products';
      if (_collections.contains(collection)) {
        try {
          final snapshot = await _firestore.collection(collection).get();
          products.addAll(snapshot.docs.map((doc) => Product.fromFirestore(doc)));
        } catch (e) {
          print('Error fetching $collection: $e');
        }
      }
    }

    return products;
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
