import 'package:flutter_test/flutter_test.dart';
import 'package:tremapp/game/logic/guess_evaluator.dart';
import 'package:tremapp/widgets/quadroJogo.dart';

void expectTiles(
  List<UiTile> actual,
  List<String> letters,
  List<TileState> states,
) {
  expect(actual, hasLength(letters.length));
  expect(actual.map((tile) => tile.letter).toList(), letters);
  expect(actual.map((tile) => tile.state).toList(), states);
}

void main() {
  test('marks exact, present, absent, and repeated letters correctly', () {
    final result = evaluateGuess('ALLEY', 'APPLE');

    expectTiles(
      result,
      ['A', 'L', 'L', 'E', 'Y'],
      [
        TileState.correct,
        TileState.present,
        TileState.absent,
        TileState.present,
        TileState.absent,
      ],
    );
  });

  test('marks every letter correct when the guess matches the answer', () {
    final result = evaluateGuess('METRO', 'METRO');

    expectTiles(
      result,
      ['M', 'E', 'T', 'R', 'O'],
      [
        TileState.correct,
        TileState.correct,
        TileState.correct,
        TileState.correct,
        TileState.correct,
      ],
    );
  });

  test('marks letters absent when none are in the answer', () {
    final result = evaluateGuess('CIVIL', 'TERMO');

    expectTiles(
      result,
      ['C', 'I', 'V', 'I', 'L'],
      [
        TileState.absent,
        TileState.absent,
        TileState.absent,
        TileState.absent,
        TileState.absent,
      ],
    );
  });

  test('consumes repeated letters from the answer only once', () {
    final result = evaluateGuess('LLAMA', 'POLAR');

    expectTiles(
      result,
      ['L', 'L', 'A', 'M', 'A'],
      [
        TileState.present,
        TileState.absent,
        TileState.present,
        TileState.absent,
        TileState.absent,
      ],
    );
  });
}