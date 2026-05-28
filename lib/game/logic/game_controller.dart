// game/logic/game_controller.dart — guarda o estado da partida e avisa a tela quando muda.
// É um ChangeNotifier: a tela escuta e se redesenha sozinha a cada notifyListeners().
import 'package:flutter/foundation.dart'; // ChangeNotifier (sem material, lógica pura de estado)
import 'package:tremapp/widgets/quadroJogo.dart'; // UiTile / TileState (modelo das células)
import 'package:tremapp/game/models/game_status.dart'; // GameStatus (playing / won / lost)
import 'package:tremapp/game/logic/guess_evaluator.dart'; // evaluateGuess (a coloração das letras)

class GameController extends ChangeNotifier {
  static const int wordLength = 5; // tamanho da palavra (5 letras por linha)
  static const int maxAttempts = 6; // numero de tentativas (6 linhas no board)

  String _answer; // o gabarito (palavra secreta); pode trocar ao reiniciar a partida
  final List<List<UiTile>> _board = []; // matriz 6x5 de tiles, começa toda vazia
  String _currentGuess = ''; // o que o jogador digitou na linha atual ainda não enviada
  GameStatus _status = GameStatus.playing; // fase da partida; começa jogando

  // Construtor: guarda o gabarito e monta o tabuleiro vazio.
  GameController({required String answer}) : _answer = answer {
    // Cria maxAttempts linhas, cada uma com wordLength tiles vazias (letra '' e estado empty).
    for (var linha = 0; linha < maxAttempts; linha++) {
      _board.add(
        List.generate(wordLength, (_) => UiTile(letter: '')),
      );
    }
  }

  // Getters: a tela só lê esses valores, nunca altera direto.
  List<List<UiTile>> get board => _board; // o tabuleiro inteiro, para desenhar
  GameStatus get status => _status; // a fase atual, para mostrar banner de fim
  String get answer => _answer; // o gabarito (útil para testes / debug)
  String get currentGuess => _currentGuess; // o que está digitado, para a tela sincronizar o campo

  // A "linha atual" é a primeira linha ainda NÃO ENVIADA.
  //
  // CUIDADO (bug clássico aqui): a definição NÃO pode ser "primeira linha toda vazia".
  // Enquanto o jogador digita, as tiles da linha viram `filled` — se exigíssemos
  // `empty`, a linha em digitação deixaria de contar e o índice pularia para a de
  // baixo, fazendo as letras irem para a linha errada. Por isso aceitamos `empty`
  // OU `filled`: o que distingue uma linha "já enviada" é ter tiles COLORIDAS
  // (correct/present/absent), e essas são justamente as que NÃO passam no teste abaixo.
  //
  // Como linhas enviadas (coloridas) reprovam no `every`, indexWhere devolve sempre a
  // primeira linha ainda editável. Retorna -1 quando todas já foram enviadas (board cheio).
  int get currentRow => _board.indexWhere(
    (row) => row.every(
      (t) => t.state == TileState.empty || t.state == TileState.filled,
    ),
  );

  // Ação: jogador digitou uma letra.
  void onLetterTyped(String letter) {
    if (_status != GameStatus.playing) return; // se o jogo acabou, ignora
    if (_currentGuess.length >= wordLength) return; // se a linha já tem 5 letras, ignora
    _currentGuess += letter.toUpperCase(); // soma a letra em maiúscula ao chute atual
    _redrawCurrentRow(); // repinta a linha com a letra nova
    notifyListeners(); // avisa a tela para redesenhar
  }

  // Ação: jogador apertou apagar.
  void onBackspace() {
    if (_currentGuess.isEmpty) return; // nada a apagar, ignora
    _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1); // tira o último caractere
    _redrawCurrentRow(); // repinta a linha já sem a letra removida
    notifyListeners(); // avisa a tela para redesenhar
  }

  // Ação principal: jogador enviou o chute.
  // Recebe uma função que diz se a palavra existe (validação contra a lista).
  // Retorna uma mensagem de erro (String) ou null quando deu tudo certo.
  String? submitGuess(bool Function(String) isValidWord) {
    if (_status != GameStatus.playing) return null; // jogo já acabou, não faz nada
    if (_currentGuess.length < wordLength) return 'Palavra incompleta'; // menos de 5 letras
    if (!isValidWord(_currentGuess)) return 'Palavra não reconhecida'; // palavra inexistente

    final row = currentRow; // descobre em qual linha gravar antes de preencher
    _board[row] = evaluateGuess(_currentGuess, _answer); // pinta a linha com verde/amarelo/cinza

    if (_currentGuess == _answer) {
      _status = GameStatus.won; // acertou tudo -> ganhou
    } else if (row == maxAttempts - 1) {
      _status = GameStatus.lost; // era a última linha e errou -> perdeu
    }

    _currentGuess = ''; // zera o chute para a próxima linha
    notifyListeners(); // avisa a tela (board novo + possível fim de jogo)
    return null; // sem erro
  }

  // Reinicia a partida com uma nova palavra: zera tudo (board, chute, status) e troca o gabarito.
  void reiniciar({required String answer}) {
    _answer = answer; // novo gabarito da próxima partida
    _currentGuess = ''; // limpa o que estava digitado
    _status = GameStatus.playing; // volta a jogar
    for (var i = 0; i < _board.length; i++) {
      // repõe cada linha com tiles vazias
      _board[i] = List.generate(wordLength, (_) => UiTile(letter: ''));
    }
    notifyListeners(); // avisa a tela para redesenhar o board zerado
  }

  // Privado: repinta apenas a linha atual conforme o que está digitado em _currentGuess.
  void _redrawCurrentRow() {
    final row = currentRow; // qual linha está sendo editada
    if (row < 0) return; // não há linha vazia (tabuleiro cheio), nada a repintar
    _board[row] = List.generate(wordLength, (i) {
      if (i < _currentGuess.length) {
        // posição já digitada: mostra a letra com estado "filled" (digitando)
        return UiTile(letter: _currentGuess[i], state: TileState.filled);
      }
      // posição ainda não digitada: célula vazia
      return UiTile(letter: '');
    });
  }
}