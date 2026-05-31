import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserModel() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    }
    return null;
  }

  Future<UserModel?> login(String email, String password) async {
    if (email.isEmpty) throw Exception("Please enter your email address.");
    if (password.isEmpty) throw Exception("Please enter your password.");
    
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(cred.user!.uid).get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception("No account found with this email.");
        case 'wrong-password':
          throw Exception("Incorrect password. Please try again.");
        case 'invalid-email':
          throw Exception("Please enter a valid email address.");
        case 'invalid-credential':
          throw Exception("Incorrect email or password. Please try again.");
        default:
          throw Exception("Login failed. Please try again.");
      }
    }
  }

  Future<UserModel?> signup({
    required String email,
    required String password,
    required String name,
    required String role,
    String? clubName,
    String? year,
    String? department,
    String? usn,
    String? branch,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception("Please fill in all required fields.");
    }
    
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        UserModel newUser = UserModel(
          id: cred.user!.uid,
          name: name,
          email: email,
          role: role,
          clubName: clubName,
          year: year,
          department: department,
          usn: usn,
          branch: branch,
        );
        await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());
        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception("An account already exists for that email.");
        case 'invalid-email':
          throw Exception("Please enter a valid email address.");
        case 'weak-password':
          throw Exception("The password provided is too weak.");
        default:
          throw Exception("Signup failed. Please try again.");
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
