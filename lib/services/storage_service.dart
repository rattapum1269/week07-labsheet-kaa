import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    // สร้างชื่อไฟล์ที่ไม่ซ้ำกันโดยใช้ sellerId และ timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = imageFile.path.split('.').last;
    final fileName = '${sellerId}_$timestamp.$extension';
    final ref = _storage.ref().child('listings').child(fileName);

    // อัปโหลดไฟล์และรอจนกว่าจะเสร็จสมบูรณ์
    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;

    // ดึง Download URL หลังอัปโหลดเสร็จ
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
