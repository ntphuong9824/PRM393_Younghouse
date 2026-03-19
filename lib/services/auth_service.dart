import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import '../firebase_options.dart';

class PhoneOtpRequest {
  final String verificationId;
  final int? resendToken;

  const PhoneOtpRequest({
	required this.verificationId,
	this.resendToken,
  });
}

class AuthService {
  static const String defaultAdminEmail = 'admin@younghouse.app';
  static const String defaultAdminPassword = 'Admin@123456';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailPassword({
	required String email,
	required String password,
  }) {
	return _auth.signInWithEmailAndPassword(
	  email: email.trim().toLowerCase(),
	  password: password,
	);
  }

  Future<UserCredential> signInOrBootstrapDefaultAdmin({
	required String email,
	required String password,
  }) async {
	final normalizedEmail = email.trim().toLowerCase();
	if (normalizedEmail != defaultAdminEmail || password != defaultAdminPassword) {
	  throw FirebaseAuthException(
		code: 'invalid-credential',
		message: 'Thong tin dang nhap admin khong hop le.',
	  );
	}

	try {
	  final credential = await _auth.signInWithEmailAndPassword(
		email: normalizedEmail,
		password: password,
	  );
	  await _upsertAdminProfile(credential.user!);
	  return credential;
	} on FirebaseAuthException catch (e) {
	  if (e.code != 'user-not-found' && e.code != 'invalid-credential') {
		rethrow;
	  }

	  final credential = await _auth.createUserWithEmailAndPassword(
		email: normalizedEmail,
		password: password,
	  );
	  await _upsertAdminProfile(credential.user!);
	  return credential;
	}
  }


		  Stream<QuerySnapshot<Map<String, dynamic>>> streamTenantsByAdmin(
			String landlordId,
		  ) {
			return _db
				.collection('users')
				.where('role', isEqualTo: 'tenant')
				.where('landlord_id', isEqualTo: landlordId)
				.snapshots();
		  }

		  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllTenants() {
			return _db
				.collection('users')
				.where('role', isEqualTo: 'tenant')
				.snapshots();
		  }

		  Future<void> createTenantByAdmin({
			required String adminId,
			required String fullName,
			required String email,
			required String password,
			required String phone,
		  }) async {
			final normalizedEmail = email.trim().toLowerCase();
			final normalizedPhone = normalizePhoneNumber(phone);
			final appName = 'admin-create-${DateTime.now().millisecondsSinceEpoch}';

			FirebaseApp? secondaryApp;
			try {
			  secondaryApp = await Firebase.initializeApp(
				name: appName,
				options: DefaultFirebaseOptions.currentPlatform,
			  );

			  final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
			  final credential = await secondaryAuth.createUserWithEmailAndPassword(
				email: normalizedEmail,
				password: password,
			  );

			  final createdUser = credential.user;
			  if (createdUser == null) {
				throw FirebaseAuthException(code: 'user-not-found');
			  }

			  final now = FieldValue.serverTimestamp();
			  await _db.collection('users').doc(createdUser.uid).set(
				{
				  'email': normalizedEmail,
				  'phone': normalizedPhone,
				  'full_name': fullName.trim(),
				  'role': 'tenant',
				  'landlord_id': adminId,
				  'is_profile_confirmed': false,
				  'created_at': now,
				  'updated_at': now,
				},
				SetOptions(merge: true),
			  );

			  await secondaryAuth.signOut();
			} finally {
			  if (secondaryApp != null) {
				await secondaryApp.delete();
			  }
			}
		  }

  Future<PhoneOtpRequest> requestPhoneOtp({
	required String phone,
	int? forceResendingToken,
  }) async {
	final completer = Completer<PhoneOtpRequest>();
	final normalizedPhone = normalizePhoneNumber(phone);

	await _auth.verifyPhoneNumber(
	  phoneNumber: normalizedPhone,
	  timeout: const Duration(seconds: 60),
	  forceResendingToken: forceResendingToken,
	  verificationCompleted: (_) {},
	  verificationFailed: (e) {
		if (!completer.isCompleted) {
		  completer.completeError(e);
		}
	  },
	  codeSent: (verificationId, resendToken) {
		if (!completer.isCompleted) {
		  completer.complete(
			PhoneOtpRequest(
			  verificationId: verificationId,
			  resendToken: resendToken,
			),
		  );
		}
	  },
	  codeAutoRetrievalTimeout: (verificationId) {
		if (!completer.isCompleted) {
		  completer.complete(PhoneOtpRequest(verificationId: verificationId));
		}
	  },
	);

	return completer.future;
  }

  Future<UserCredential> signInWithPhoneOtp({
	required String verificationId,
	required String smsCode,
  }) {
	final credential = PhoneAuthProvider.credential(
	  verificationId: verificationId,
	  smsCode: smsCode.trim(),
	);
	return _auth.signInWithCredential(credential);
  }

  String normalizePhoneNumber(String input) {
	final digitsOnly = input.replaceAll(RegExp(r'\s+'), '');
	if (digitsOnly.startsWith('+')) return digitsOnly;
	if (digitsOnly.startsWith('0')) return '+84${digitsOnly.substring(1)}';
	if (digitsOnly.startsWith('84')) return '+$digitsOnly';
	return digitsOnly;
  }

  Future<Map<String, dynamic>> getOrCreateUserProfile(User user) async {
	final docRef = _db.collection('users').doc(user.uid);
	final snapshot = await docRef.get();

	if (snapshot.exists) {
	  return snapshot.data() ?? <String, dynamic>{};
	}

	final data = <String, dynamic>{
	  'email': user.email ?? '',
	  'phone': user.phoneNumber ?? '',
	  'full_name': user.displayName ?? (user.email?.split('@').first ?? 'Nguoi dung'),
	  'role': 'tenant',
	  'is_profile_confirmed': false,
	  'created_at': FieldValue.serverTimestamp(),
	  'updated_at': FieldValue.serverTimestamp(),
	};

	await docRef.set(data, SetOptions(merge: true));
	return data;
  }

		  Future<bool> isTenantProfileComplete({
			required String userId,
			required Map<String, dynamic> profile,
		  }) async {
			final dateOfBirth = profile['date_of_birth'];
			final hasDateOfBirth = dateOfBirth is Timestamp || dateOfBirth is DateTime;
			final hasIdNumber = (profile['id_number'] as String?)?.trim().isNotEmpty == true;

			if (!hasDateOfBirth || !hasIdNumber) {
			  return false;
			}

			final guardianSubcollection = await _db
				.collection('users')
				.doc(userId)
				.collection('guardians')
				.limit(1)
				.get();
			if (guardianSubcollection.docs.isNotEmpty) {
			  return true;
			}

			// Fallback for records that may exist only in top-level guardians collection.
			final guardianTopLevel = await _db
				.collection('guardians')
				.where('user_id', isEqualTo: userId)
				.limit(1)
				.get();
			return guardianTopLevel.docs.isNotEmpty;
		  }

  Future<void> signOut() => _auth.signOut();

  /// Lấy UID của admin (user có role = 'admin') từ Firestore
  Future<String?> getAdminUid() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<void> _upsertAdminProfile(User user) async {
	final now = FieldValue.serverTimestamp();
	await _db.collection('users').doc(user.uid).set(
	  {
		'email': user.email ?? defaultAdminEmail,
		'phone': user.phoneNumber ?? '',
		'full_name': user.displayName ?? 'Quan tri vien',
		'role': 'admin',
		'is_profile_confirmed': true,
		'created_at': now,
		'updated_at': now,
	  },
	  SetOptions(merge: true),
	);
  }
}
