import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'home.dart';
import 'ranking.dart';
import 'login.dart';
import 'registro.dart';


class App extends StatelessWidget {
  const App({super.key});
@override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Rotas principais do app: login/registro são telas independentes e /game abre o shell com navbar.
      routes: {
          // "/game": (context) => const GameScreen(),
          "/login": (context) => LoginPage(),
          "/registro": (context) => RegistroPage(),
          "/ranking": (context) => const Ranking(),
          "/home": (context) => const Home(),
      },

      initialRoute: "/login",
    );   
  }
}