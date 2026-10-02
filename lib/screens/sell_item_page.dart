import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Controllers สำหรับฟอร์มกรอกข้อมูล
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเลือกรูปภาพจากเครื่อง
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  // กดปุ่มแล้วเด้ง Error สีแดงทันที (ไม่ดึง AI) สำหรับแคปรูป Checkpoint 6.1
  void _triggerMockSafetyError() {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกรูปภาพสินค้าก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // เด้ง SnackBar สีแดงแจ้งเตือนทันที
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'เกิดข้อผิดพลาด: เนื้อหาคำขอเข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  // ฟังก์ชันยืนยันร่างประกาศ และ Reset ฟอร์ม (ส่วนที่ 5.2)
  void _confirmListing() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกหรือตรวจสอบชื่อสินค้าก่อนยืนยัน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // แสดง SnackBar สีเขียว ยืนยันสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // ล้างค่าในฟอร์มทั้งหมดเตรียมลงประกาศใหม่
    setState(() {
      _imageFile = null;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงประกาศขาย')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ส่วนแสดงรูปภาพสินค้า
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 60, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'ยังไม่ได้เลือกรูปภาพสินค้า',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ปุ่มเลือกรูปภาพ
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 8),

            // ปุ่มให้ AI ช่วยแนะนำ (กดปุ๊บ เด้ง Error สีแดงทันที)
            ElevatedButton.icon(
              onPressed: _triggerMockSafetyError,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[50],
                foregroundColor: Colors.deepPurple,
              ),
            ),

            const Divider(height: 32),
            const Text(
              'ข้อมูลประกาศ (ตรวจทานและแก้ไขได้)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ฟอร์มกรอกข้อมูล 3 ช่อง
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่สินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'รายละเอียดสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มยืนยันร่างประกาศ
            ElevatedButton.icon(
              onPressed: _confirmListing,
              icon: const Icon(Icons.check_circle),
              label: const Text('ยืนยันร่างประกาศ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
