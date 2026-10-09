import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String? sellerId; // nullable เพราะสินค้าจาก API ไม่มี sellerId

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final title = json['title'] as String;
    final price = (json['price'] as num).toDouble();
    final description = json['description'] as String;
    final category = json['category'] as String;
    final imageUrl = json['image'] as String;

    return Item(
      id: id,
      title: title,
      price: price,
      description: description,
      category: category,
      imageUrl: imageUrl,
    );
  }

  // แปลง Item เป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }

  // สร้าง Item จาก DocumentSnapshot ของ Firestore
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      id: data['id'] is int ? data['id'] as int : doc.id.hashCode,
      title: (data['title'] ?? '') as String,
      price: ((data['price'] ?? 0) as num).toDouble(),
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? data['image'] ?? '') as String,
      sellerId: data['sellerId'] as String?,
    );
  }
}
