import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/listing_draft_repository.dart';
import '../repositories/item_repository_firestore.dart';
import '../services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  final _storageService = StorageService();
  final _firestoreRepo = ItemRepositoryFirestore();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    setState(() {
      _draftsFuture = widget.repository.getAllDrafts();
    });
  }

  // ฟังก์ชันถามราคาและโพสต์ขายจริง
  Future<void> _publishDraft(ListingDraftRow draft) async {
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // 1. แสดง Dialog ถามราคาสินค้า
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ตั้งราคาสำหรับ "${draft.title}"'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'ราคา (บาท)',
              border: OutlineInputBorder(),
              prefixText: '฿ ',
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกราคา';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'กรุณากรอกตัวเลขที่มากกว่า 0';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('โพสต์ขาย'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final price = double.parse(priceController.text.trim());
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์ขาย')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      // ตรวจสอบสัญญาณอินเทอร์เน็ตก่อนโพสต์ทันที
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('ไม่มีสัญญาณอินเทอร์เน็ต');
        }
      } catch (_) {
        throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ (Offline)');
      }

      String downloadUrl = '';

      // 2. อัปโหลดรูปภาพขึ้น Storage (หากติด Permission/Billing ให้ใช้ local imagePath แทน)
      if (draft.imagePath.isNotEmpty && File(draft.imagePath).existsSync()) {
        try {
          final imageFile = File(draft.imagePath);
          downloadUrl = await _storageService.uploadListingImage(
            imageFile,
            user.uid,
          );
        } catch (_) {
          // หาก Storage ใช้ไม่ได้ ให้ใช้ local path ของรูปจริงในเครื่อง
          downloadUrl = draft.imagePath;
        }
      }

      // 3. สร้าง Item และเขียนลง Firestore
      final newItem = Item(
        id: DateTime.now().millisecondsSinceEpoch,
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: downloadUrl,
        sellerId: user.uid,
      );

      await _firestoreRepo.postItem(newItem, sellerId: user.uid).timeout(
        const Duration(seconds: 4),
        onTimeout: () => throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ (Offline)'),
      );

      // 4. ลบร่างออกจาก Local Database หลังโพสต์สำเร็จ
      await widget.repository.deleteDraft(draft.id);

      // 5. Refresh หน้าจอและแสดง SnackBar
      _loadDrafts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('โพสต์ขาย "${draft.title}" บน Campus Marketplace สำเร็จแล้ว!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการโพสต์: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<ListingDraftRow>>(
            future: _draftsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
              }
              final drafts = snapshot.data ?? [];
              if (drafts.isEmpty) {
                return const Center(
                  child: Text(
                    'ยังไม่มีร่างประกาศที่บันทึกไว้',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  final draft = drafts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: draft.imagePath.isNotEmpty &&
                              File(draft.imagePath).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(draft.imagePath),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.drafts, color: Colors.grey),
                            ),
                      title: Text(
                        draft.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'หมวดหมู่: ${draft.category}\nแก้ไขล่าสุด: ${draft.updatedAt.toLocal().toString().split('.')[0]}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ปุ่มโพสต์ขายจริง
                          ElevatedButton.icon(
                            onPressed: _isPosting ? null : () => _publishDraft(draft),
                            icon: const Icon(Icons.cloud_upload, size: 16),
                            label: const Text('โพสต์ขายจริง'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // ปุ่มลบร่าง
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _isPosting
                                ? null
                                : () async {
                                    try {
                                      await widget.repository.deleteDraft(draft.id);
                                      _loadDrafts();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('ลบร่าง "${draft.title}" เรียบร้อยแล้ว'),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // แสดง Loading Indicator Overlay ระหว่างอัปโหลด
          if (_isPosting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'กำลังอัปโหลดรูปภาพและโพสต์ขึ้นระบบ...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
