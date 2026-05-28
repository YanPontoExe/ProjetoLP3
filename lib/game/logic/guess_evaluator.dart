// game/logic/guess_evaluator.dart  — PURO, sem Flutter
import 'package:tremapp/widgets/quadroJogo.dart';

List<UiTile> evaluateGuess(String guess, String answer) {
  assert(guess.length == answer.length);

  final result = List<UiTile>.filled(answer.length,UiTile(letter: ''));
  final answerChars = answer.split(''); //estoque mutável 
  final guessChars = guess.split(''); 

  //mapear status verdes
  for (var i = 0; i <guessChars.length; i++) { // enquanto estiver na letra (quadrado) e ainda não terminou a palavra
    if (guessChars[i] == answerChars[i]) { // se a letra (indice i) do chute for igual a da palavra certa
      result[i] = UiTile(letter: guessChars[i], state: TileState.correct); //puxa o estado de cor verde para a letra no quadro
      answerChars[i] = ''; // letra da resposta ja foi consumido
      guessChars[i] = ''; // letra do chute ja foi tratada
    }
  }

  //mapear restantes (amarelos e cinzas)
  for (var i = 0; i<guessChars.length; i++) {
    if (guessChars[i].isEmpty) continue; // se a letra ja foi validada como verde pela passagem anterior, ode seguir para a próxima
    final idx = answerChars.indexOf(guessChars[i]); //final idx procura dentro de answerChars (a palavra resposta) a letra que está na posição i de guessChars (a tentativa do jogador), guardando em idx a posição onde ela foi encontrada, ou -1 se não existir.
    if(idx >= 0) { // se a letra do chute existir na palavra secreta (mas em local diferente)
      result[i] = UiTile(letter: guessChars[i], state: TileState.present); //pega a letra do chute que existe na palavra correta mas está no lugar errado e coloca com a cor amarela (state "present")
      answerChars[idx] = ''; //consome do estoque (parametro para evitar duplicatas, pois se uma letra "O" ja foi consumida, a outra "O" que resta não buga com o mesmo estado)
    } else {
      result[i] = UiTile(letter: guessChars[i], state: TileState.absent); // se não sobrou mais letras presentes, todo resto não existe na palavra (state "absent")
    }
  }
  return result; // retorna o resultado
}