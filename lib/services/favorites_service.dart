import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class FavoritesService {
  final FirebaseFirestore _firestore;
  final String Function() _getUid;

  FavoritesService({
    FirebaseFirestore? firestore,
    String Function()? getUid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _getUid = getUid ?? (() => FirebaseAuth.instance.currentUser!.uid);

  String get _uid => _getUid();

  DocumentReference get _ref =>
      _firestore.collection('users').doc(_uid).collection('data').doc('favorites');

  Future<List<Product>> getFavorites() async {
    final doc = await _ref.get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>?;
    final list = data?['products'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveFavorites(List<Product> favorites) async {
    await _ref.set({'products': favorites.map((p) => p.toJson()).toList()});
  }
}
