import 'package:flutter/material.dart';

// Aba de ranking exibida dentro do Game, sem Scaffold próprio para não duplicar AppBar/navbar.
class Ranking extends StatelessWidget {
  const Ranking({super.key});

  @override
  Widget build(BuildContext context) {
    // Conteúdo central da aba de ranking.
    return const Center(
      child: Text(
        "RANKING",
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
    );
  }
}