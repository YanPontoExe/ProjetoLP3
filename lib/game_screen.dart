import 'package:flutter/material.dart';
import 'widgets/quadroJogo.dart'; // BoardUiWidget (desenho do tabuleiro)
import 'game/logic/game_controller.dart'; // GameController (estado da partida)
import 'game/models/game_status.dart'; // GameStatus (playing / won / lost)
import 'game/data/palavras.dart'; // palavraDoDia, palavraAleatoria, palavrasGabarito, palavrasValidas
import 'game/services/score_service.dart'; // registrarVitoria (soma pontos ao vencer)

// Conteúdo isolado da lógica principal do jogo; fica embutido no shell Game.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

// AutomaticKeepAliveClientMixin mantém este State vivo ao trocar de aba no PageView,
// para a partida não recomeçar do zero quando o jogador volta para o jogo.
class _GameScreenState extends State<GameScreen>
    with AutomaticKeepAliveClientMixin {
  late final GameController controller; // dono do estado; criado uma vez no initState
  final TextEditingController _campo = TextEditingController(); // texto do TextField
  bool _vitoriaRegistrada = false; // evita somar pontos mais de uma vez

  @override
  bool get wantKeepAlive => true; // exige que o mixin preserve este State

  @override
  void initState() {
    super.initState();
    // Sorteia a palavra do dia (igual para todos hoje) e monta o controller com ela.
    controller = GameController(answer: palavraDoDia(palavrasGabarito));
  }

  @override
  void dispose() {
    _campo.dispose(); // libera o controller do TextField
    controller.dispose(); // libera o ChangeNotifier
    super.dispose();
  }

  // Reconcilia o texto do TextField com o estado do controller.
  //
  // PROBLEMA: o TextField avisa pelo onChanged passando a STRING INTEIRA atual (ex.:
  // "CAS"), mas o controller pensa em EVENTOS discretos (onLetterTyped / onBackspace).
  // Precisamos traduzir "qual é o texto agora" para "o que mudou desde a última vez".
  //
  // SOLUÇÃO: comparar o tamanho do texto novo com o do chute que o controller já tem.
  //   - texto MAIOR  → o usuário digitou letras: enviamos só os caracteres novos
  //     (do fim do antigo até o fim do novo), um onLetterTyped para cada.
  //   - texto MENOR  → o usuário apagou: chamamos onBackspace uma vez por caractere
  //     que sumiu, para o controller encolher o chute na mesma medida.
  // Manter o controller como fonte única da verdade evita que campo e tabuleiro
  // fiquem dessincronizados (o board é desenhado a partir do controller, não do campo).
  void _aoDigitar(String texto) {
    final atual = controller.currentGuess; // o que o controller registrou até agora
    if (texto.length > atual.length) {
      // digitou: percorre só a parte nova do texto e envia letra a letra
      for (var i = atual.length; i < texto.length; i++) {
        controller.onLetterTyped(texto[i]);
      }
    } else {
      // apagou: um backspace para cada caractere a menos
      for (var i = texto.length; i < atual.length; i++) {
        controller.onBackspace();
      }
    }
  }

  // Envia o chute atual; mostra erro em SnackBar e, na vitória, registra os pontos.
  void _enviar() {
    final erro = controller.submitGuess(
      (palavra) => palavrasValidas.contains(palavra), // valida contra a lista
    );

    if (erro != null) {
      // chute recusado (incompleto ou inexistente): avisa o jogador
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return; // mantém o que está digitado para o usuário corrigir
    }

    _campo.clear(); // chute aceito: limpa o campo para a próxima tentativa

    // Só pontua na transição para `won`, e só UMA vez. A flag _vitoriaRegistrada
    // impede pontuação dupla caso _enviar() seja chamado de novo após a vitória.
    if (controller.status == GameStatus.won && !_vitoriaRegistrada) {
      _vitoriaRegistrada = true; // trava: a partir daqui não soma de novo

      // QUANTAS TENTATIVAS o jogador usou? Após o submit vitorioso, a linha que ele
      // acertou já está colorida, então `currentRow` aponta para a PRÓXIMA linha vazia
      // — cujo índice é exatamente o número de linhas já usadas. Exceção: se ele
      // acertou na última linha, não sobra linha vazia e currentRow vira -1; nesse
      // caso usou todas as maxAttempts. (Ex.: acertou na 1ª linha → currentRow == 1.)
      final tentativas = controller.currentRow == -1
          ? GameController.maxAttempts
          : controller.currentRow;
      registrarVitoria(tentativas: tentativas); // soma (7 - tentativas) * 10 no Firestore
    }
  }

  // Reinicia a partida com uma palavra nova (sorteada), limpando campo e trava de pontos.
  void _jogarDeNovo() {
    _vitoriaRegistrada = false; // libera para pontuar de novo na próxima vitória
    _campo.clear(); // limpa o campo de digitação
    controller.reiniciar(answer: palavraAleatoria(palavrasGabarito)); // nova palavra + board zerado
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // obrigatório pelo AutomaticKeepAliveClientMixin
    // ListenableBuilder redesenha sozinho a cada notifyListeners() do controller.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final acabou = controller.status != GameStatus.playing; // jogo terminou?
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              BoardUiWidget(board: controller.board), // desenha o tabuleiro do controller
              const SizedBox(height: 82),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _campo,
                  enabled: !acabou, // trava o campo quando o jogo termina
                  onChanged: _aoDigitar, // sincroniza cada mudança com o controller
                  onSubmitted: (_) => _enviar(), // enviar pelo teclado dispara o chute
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters, // sugere maiúsculas
                  maxLength: GameController.wordLength, // no máximo 5 letras
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
              const SizedBox(height: 16),
              // Banner de fim de jogo: só aparece quando o jogo termina.
              if (acabou) ...[
                Text(
                  controller.status == GameStatus.won
                      ? 'Você ganhou!' // vitória
                      : 'Fim de jogo! A palavra era ${controller.answer}', // derrota mostra a resposta
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _jogarDeNovo, // gera uma nova palavra e zera o tabuleiro
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(253, 128, 46, 1.0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Jogar de novo'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
