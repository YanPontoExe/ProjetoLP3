import 'package:flutter/material.dart';
import 'widgets/quadroJogo.dart';

const int kWordLength  = 5; // tamanho da palavra (fixo em 5 para este jogo)
const int kMaxAttempts = 6; // numero max de tentativas (quantidade de linhas do board)
var inputGuess = ""; // palavra sendo digitada no momento

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
    // Estrutura inicial da tela do jogo: título e quadro visual.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        BoardUiWidget(board: _buildEmptyBoard()),
        Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 20),
          child: 
          TextField(
              scrollPadding: EdgeInsets.only(bottom: 40),
              controller: inputGuess.isEmpty ? null : TextEditingController(text: inputGuess),
              textAlign: TextAlign.center,
              maxLength: kWordLength,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
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
            ), // TextField
        ),
      ],
    );
  }
}
