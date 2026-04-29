import 'package:flutter/material.dart';
import 'package:tremapp/game.dart';


class App extends StatelessWidget {
  const App({super.key});
@override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      routes: {
          "/game": (context) => const Game(),
      },

      initialRoute: "/game",
    );   
  }
}