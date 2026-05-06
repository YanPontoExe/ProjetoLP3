import 'package:flutter/material.dart';
import 'game.dart';
import 'login.dart';


class App extends StatelessWidget {
  const App({super.key});
@override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      routes: {
          "/game": (context) => const Game(),
          "/login": (context) => LoginPage(),
      },

      initialRoute: "/login",
    );   
  }
}