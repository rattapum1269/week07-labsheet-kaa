import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final CollectionReference _itemsRef =
      FirebaseFirestore.instance.collection('items');

  @override
  Future<List<Item>> getItems() async {
    final querySnapshot = await _itemsRef.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _mapDocToItem(doc.id, data);
    }).toList();
  }

  // โพสต์สินค้าใหม่ลง Firestore
  Future<void> postItem(Item item, {String? sellerId}) async {
    final data = item.toFirestore();
    if (sellerId != null && (data['sellerId'] == null || data['sellerId'] == '')) {
      data['sellerId'] = sellerId;
    }
    data['createdAt'] = FieldValue.serverTimestamp();
    await _itemsRef.add(data);
  }

  // ฟังรายการประกาศของผู้ใช้แบบ Real-time
  Stream<List<Item>> watchMyListings(String sellerId) {
    return _itemsRef
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapDocToItem(doc.id, data);
      }).toList();
    });
  }

  Item _mapDocToItem(String docId, Map<String, dynamic> data) {
    return Item(
      id: data['id'] is int ? data['id'] as int : docId.hashCode,
      title: (data['title'] ?? '') as String,
      price: ((data['price'] ?? 0) as num).toDouble(),
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? data['image'] ?? '') as String,
    );
  }
}
