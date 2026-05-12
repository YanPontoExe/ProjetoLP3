import 'package:flutter/material.dart';

// Conteúdo isolado da lógica principal do jogo; fica embutido no shell Game.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder da área principal do jogo, pronto para receber a lógica real.
    return const Center(
      child: Text(
        "JOGO",
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
    );
  }
}
