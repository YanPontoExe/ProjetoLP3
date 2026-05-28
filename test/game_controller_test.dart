import 'package:flutter_test/flutter_test.dart'; // ferramentas de teste (test, expect)
import 'package:tremapp/game/logic/game_controller.dart'; // o controller que vamos testar
import 'package:tremapp/game/models/game_status.dart'; // GameStatus (won / lost / playing)

// Helper: digita cada letra da palavra, uma a uma, no controller.
void digitar(GameController c, String palavra) {
  for (final letra in palavra.split('')) {
    c.onLetterTyped(letra); // simula o toque em cada tecla
  }
}

// Validador de palavra usado nos testes: aceita só as palavras desta lista.
bool sempreValido(String _) => true; // versão que aceita qualquer palavra

void main() {
  test('digitar letras enche a linha e backspace apaga', () {
    final c = GameController(answer: 'TERMO'); // gabarito conhecido

    digitar(c, 'TER'); // digita 3 letras
    // a linha atual (0) deve mostrar T, E, R nas 3 primeiras posições
    expect(c.board[0][0].letter, 'T');
    expect(c.board[0][1].letter, 'E');
    expect(c.board[0][2].letter, 'R');

    c.onBackspace(); // apaga o último (R)
    expect(c.board[0][2].letter, ''); // posição volta a ficar vazia
  });

  test('submitGuess com menos de 5 letras devolve "Palavra incompleta"', () {
    final c = GameController(answer: 'TERMO');
    digitar(c, 'TER'); // só 3 letras
    final erro = c.submitGuess(sempreValido); // tenta enviar incompleta
    expect(erro, 'Palavra incompleta'); // deve recusar com essa mensagem
  });

  test('palavra fora da lista devolve "Palavra não reconhecida"', () {
    final c = GameController(answer: 'TERMO');
    digitar(c, 'XXXXX'); // 5 letras, mas inexistente
    final erro = c.submitGuess((_) => false); // validador diz que não existe
    expect(erro, 'Palavra não reconhecida'); // deve recusar com essa mensagem
  });

  test('chutar o gabarito leva status para won', () {
    final c = GameController(answer: 'TERMO');
    digitar(c, 'TERMO'); // chuta exatamente a palavra secreta
    final erro = c.submitGuess(sempreValido); // envia
    expect(erro, isNull); // sem erro
    expect(c.status, GameStatus.won); // venceu
  });

  test('errar 6 vezes leva status para lost', () {
    final c = GameController(answer: 'TERMO');
    for (var i = 0; i < GameController.maxAttempts; i++) {
      digitar(c, 'CASAL'); // chute errado, mas válido
      c.submitGuess(sempreValido); // envia cada tentativa
    }
    expect(c.status, GameStatus.lost); // após 6 erros, perdeu
  });
}