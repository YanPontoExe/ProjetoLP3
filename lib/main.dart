import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';

const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyCoQ4CEYaAdaA5VUxrKG9BZjzFKXxDes1w",
  authDomain: "tasklist-9b74e.firebaseapp.com",
  projectId: "tasklist-9b74e",
  storageBucket: "tasklist-9b74e.firebasestorage.app",
  messagingSenderId: "816081176937",
  appId: "1:816081176937:web:33a87cf382a317ec2f55f8"
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);
  runApp(const App());
}

