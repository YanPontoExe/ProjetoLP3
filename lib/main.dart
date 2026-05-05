import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';

const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyBEt_GcMQa0MG2lBOUpIm18TnLIXTjFxWE",
  authDomain: "metro-12243.firebaseapp.com",
  projectId: "metro-12243",
  storageBucket: "metro-12243.firebasestorage.app",
  messagingSenderId: "1046779146859",
  appId: "1:1046779146859:web:5792d58084e2afdbc2772e",
  measurementId: "G-XEN821YR0M"
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);
  runApp(const App());
}

