import 'package:cloud_firestore/cloud_firestore.dart';

class FcmTokenRepository {
  final FirebaseFirestore _db;

  FcmTokenRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> saveToken({
    required String userId,
    required String token,
    String? deviceInfo,
  }) async {
    final docRef = _db.collection('fcm_tokens').doc();
    await docRef.set({
      'userId': userId,
      'token': token,
      'deviceInfo': deviceInfo,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeToken(String tokenId) async {
    await _db.collection('fcm_tokens').doc(tokenId).delete();
  }

  Future<void> updateToken(String tokenId) async {
    await _db.collection('fcm_tokens').doc(tokenId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}