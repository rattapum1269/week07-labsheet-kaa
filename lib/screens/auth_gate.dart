import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'main_scaffold.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';

class AuthGate extends StatelessWidget {
  final List<ItemRepository> itemRepositories;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;

  const AuthGate({
    super.key,
    required this.itemRepositories,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // กำลังรอเชื่อมต่อ / ดึงสถานะ
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ยังไม่ล็อกอิน (snapshot.data == null)
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // ล็อกอินแล้ว -> สลับไปหน้า MainScaffold
        return MainScaffold(
          itemRepositories: itemRepositories,
          favoritesRepository: favoritesRepository,
          draftRepository: draftRepository,
        );
      },
    );
  }
}
