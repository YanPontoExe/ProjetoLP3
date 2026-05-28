import 'package:flutter/material.dart';
import 'widgets/quadroJogo.dart';

const int kWordLength  = 5; // tamanho da palavra (fixo em 5 para este jogo)
const int kMaxAttempts = 6; // numero max de tentativas (quantidade de linhas do board)

// Conteúdo isolado da lógica principal do jogo; fica embutido no shell Game.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Monta um board vazio para que o quadro já apareça na tela.
  List<List<UiTile>> _buildEmptyBoard() {
    return List.generate( kMaxAttempts, (_) 
    => List.generate( kWordLength, (_) => UiTile(letter: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O Scaffold já trata o teclado; aqui deixamos só rolagem e espaçamento estável.
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          BoardUiWidget(board: _buildEmptyBoard()),
          const SizedBox(height: 82),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              scrollPadding: const EdgeInsets.only(bottom: 120),
              textAlign: TextAlign.center,
              maxLength: kWordLength,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    width: 2.5,
                  ),
                ),
                labelText: "Digite sua palavra",
                labelStyle: TextStyle(color: Color.fromRGBO(253, 128, 46, 1.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
