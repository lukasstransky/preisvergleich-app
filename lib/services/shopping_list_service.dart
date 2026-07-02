import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_list.dart';

class ShoppingListService {
  final FirebaseFirestore _firestore;
  final String Function() _getUid;

  ShoppingListService({
    FirebaseFirestore? firestore,
    String Function()? getUid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _getUid = getUid ?? (() => FirebaseAuth.instance.currentUser!.uid);

  String get _uid => _getUid();

  CollectionReference get _listsRef =>
      _firestore.collection('users').doc(_uid).collection('shopping_lists');

  DocumentReference get _settingsRef =>
      _firestore.collection('users').doc(_uid).collection('settings').doc('data');

  Future<List<ShoppingList>> getAllLists() async {
    final snapshot = await _listsRef.orderBy('createdAt').get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return ShoppingList.fromJson(data);
    }).toList();
  }

  Future<String?> getActiveListId() async {
    final doc = await _settingsRef.get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>?)?['activeListId'] as String?;
  }

  Future<void> setActiveListId(String id) async {
    await _settingsRef.set({'activeListId': id}, SetOptions(merge: true));
  }

  Future<ShoppingList> createList(String name) async {
    final docRef = _listsRef.doc();
    final newList = ShoppingList(
      id: docRef.id,
      name: name,
      items: [],
      createdAt: DateTime.now(),
    );
    final data = newList.toJson()..remove('id');
    await docRef.set(data);
    await setActiveListId(docRef.id);
    return newList;
  }

  Future<void> deleteList(String id) async {
    await _listsRef.doc(id).delete();
  }

  Future<void> updateList(ShoppingList list) async {
    final data = list.toJson()..remove('id');
    await _listsRef.doc(list.id).set(data);
  }
}
