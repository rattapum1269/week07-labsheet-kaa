import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryApi implements ItemRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  @override
  Future<List<Item>> getItems() async {
    final uri = Uri.parse(_baseUrl);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return _fallbackItems;
    } catch (_) {
      // หากเกิด Error เช่น เซิร์ฟเวอร์ล่ม (521) ให้ใช้ข้อมูลสำรองเพื่อทดสอบแอป
      return _fallbackItems;
    }
  }

  static const List<Item> _fallbackItems = [
    Item(
      id: 1,
      title: 'Fjallraven - Foldsack No. 1 Backpack',
      price: 109.95,
      description: 'Your perfect pack for everyday use and walks in the forest.',
      category: "men's clothing",
      imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=300',
    ),
    Item(
      id: 2,
      title: 'Mens Casual Premium Slim Fit T-Shirts',
      price: 22.3,
      description: 'Slim-fitting style, contrast raglan long sleeve.',
      category: "men's clothing",
      imageUrl: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=300',
    ),
    Item(
      id: 3,
      title: 'Mens Cotton Jacket',
      price: 55.99,
      description: 'Great outerwear jackets for Spring/Autumn/Winter.',
      category: "men's clothing",
      imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=300',
    ),
    Item(
      id: 4,
      title: 'Mens Casual Slim Fit',
      price: 15.99,
      description: 'The color could be slightly different between on the screen and in practice.',
      category: "men's clothing",
      imageUrl: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=300',
    ),
  ];
}
