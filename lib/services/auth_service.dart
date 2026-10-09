import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream สถานะการล็อกอิน
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ดึง User ปัจจุบัน
  User? get currentUser => _auth.currentUser;

  // สมัครสมาชิกด้วย Email & Password
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ กรุณาลองใหม่อีกครั้ง';
    }
  }

  // เข้าสู่ระบบด้วย Email & Password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ กรุณาลองใหม่อีกครั้ง';
    }
  }

  // เข้าสู่ระบบด้วย Google
  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final authorization = await googleUser.authorizationClient.authorizationForScopes(['email']);
      final String? accessToken = authorization?.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'ไม่สามารถเข้าสู่ระบบด้วย Google ได้: $e';
    }
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        GoogleSignIn.instance.signOut(),
      ]);
    } catch (e) {
      throw 'ไม่สามารถออกจากระบบได้ กรุณาลองใหม่อีกครั้ง';
    }
  }

  // แปลง FirebaseAuthException code เป็นภาษาไทย
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานไปแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านง่ายเกินไป ควรมีความยาวอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้ในระบบ';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'too-many-requests':
        return 'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'network-request-failed':
        return 'เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย กรุณาตรวจสอบอินเทอร์เน็ต';
      case 'operation-not-allowed':
        return 'ระบบยังไม่ได้เปิดใช้งานวิธีเข้าสู่ระบบนี้';
      default:
        return 'เกิดข้อผิดพลาด: ${e.message ?? e.code}';
    }
  }
}
