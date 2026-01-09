import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> signOut() => _auth.signOut();

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

  Future<void> _createUserDocIfNeeded({
    required String uid,
    required String email,
    String? name,
  }) async {
    final ref = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        // Opcional: actualiza lastLoginAt si quieres
        final Map<String, dynamic> updateData = {
          'lastLoginAt': FieldValue.serverTimestamp(),
        };
        if (name != null && name.isNotEmpty) {
          updateData['name'] = name;
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
        'syllabusId': 'GEN_CV',
      });

      // Documento de stats base (dashboard)
      final summaryRef = ref.collection('stats').doc('summary');
      tx.set(summaryRef, StatsSummary.initialData());
    });
  }
}
