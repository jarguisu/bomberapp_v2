import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../stats/stats_repository.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();

    final cred = await _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );

    if (cred.user != null && trimmedName.isNotEmpty) {
      await cred.user!.updateDisplayName(trimmedName);
    }

    // Crear perfil base en Firestore
    await _createUserDocIfNeeded(
      uid: cred.user!.uid,
      email: cred.user!.email ?? trimmedEmail,
      name: trimmedName,
    );

    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});

      final cred = await _auth.signInWithPopup(provider);
      final user = cred.user;
      if (user != null) {
        await _createUserDocIfNeeded(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
        );
      }
      return cred;
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw StateError('login-cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user != null) {
      await _createUserDocIfNeeded(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
      );
    }
    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');

    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).update({'name': name.trim()});
  }

  Future<void> updatePhotoUrl(String? photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');

    await user.updatePhotoURL(photoUrl?.trim());
    await _db
        .collection('users')
        .doc(user.uid)
        .update({'photoUrl': photoUrl?.trim() ?? ''});
  }

  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');

    final credential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updateEmail(newEmail.trim());
    await _db.collection('users').doc(user.uid).update({
      'email': newEmail.trim(),
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');

    final credential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<bool> isProUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snap = await _db.collection('users').doc(user.uid).get();
    final data = snap.data();
    if (data == null) return false;

    final plan = (data['plan'] ?? 'free').toString().toLowerCase();
    if (plan != 'pro') return false;

    final untilRaw = data['planUntil'];
    if (untilRaw == null) return true;

    if (untilRaw is! Timestamp) return true;
    final until = untilRaw.toDate();

    final status = (data['planStatus'] ?? '').toString().toLowerCase();
    if (status == 'expired') return false;

    return until.isAfter(DateTime.now());
  }

  Future<void> _createUserDocIfNeeded({
    required String uid,
    required String email,
    String? name,
  }) async {
    final ref = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final data = snap.data() ?? <String, dynamic>{};
        final Map<String, dynamic> updateData = {
          'lastLoginAt': FieldValue.serverTimestamp(),
        };
        if (name != null && name.isNotEmpty) {
          updateData['name'] = name;
        }

        final currentPlan = (data['plan'] ?? 'free').toString().toLowerCase();
        if (data['plan'] != currentPlan) {
          updateData['plan'] = currentPlan;
        }

        if (!data.containsKey('planSource')) {
          updateData['planSource'] = null;
        }
        if (!data.containsKey('planProduct')) {
          updateData['planProduct'] = null;
        }
        if (!data.containsKey('planStatus')) {
          updateData['planStatus'] = null;
        }
        if (!data.containsKey('planUntil')) {
          updateData['planUntil'] = null;
        }
        if (!data.containsKey('hasSeenTutorial')) {
          // Usuarios ya existentes: no mostrar tutorial automáticamente.
          updateData['hasSeenTutorial'] = true;
        }

        tx.update(ref, updateData);
        return;
      }

      tx.set(ref, {
        'email': email,
        'name': name ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'plan': 'free',
        'planSource': null,
        'planProduct': null,
        'planStatus': null,
        'planUntil': null,
        'hasSeenTutorial': false,
        'syllabusId': 'GEN_CV',
      });

      // Documento de stats base (dashboard)
      final summaryRef = ref.collection('stats').doc('summary');
      tx.set(summaryRef, StatsSummary.initialData());
    });
  }
}
