import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tremapp/game/logic/game_controller.dart';
import 'package:tremapp/game/logic/guess_evaluator.dart';
import 'package:tremapp/game/models/game_status.dart';
import 'package:tremapp/widgets/quadroJogo.dart';
import 'package:tremapp/game/data/palavras.dart';
import 'package:tremapp/game/data/datas.dart';

import 'test_metro_mockito.mocks.dart'; // arquivo gerado pelo build_runner

// Diz ao build_runner para gerar o mock desta classe
abstract class WordValidator {
  bool call(String word);
}

@GenerateMocks([WordValidator])
void main() {
  group('GuessEvaluator — avaliação do chute', () {
    test('T01 — todas as letras corretas', () {
      final r = evaluateGuess('TERMO', 'TERMO');
      expect(r.every((t) => t.state == TileState.correct), isTrue);
    });

    test('T02 — nenhuma letra existe na palavra', () {
      final r = evaluateGuess('BBBBB', 'TERMO');
      expect(r.every((t) => t.state == TileState.absent), isTrue);
    });

    test('T03 — letras presentes mas no lugar errado', () {
      final r = evaluateGuess('OTERM', 'TERMO');
      expect(r.any((t) => t.state == TileState.correct), isFalse);
      expect(r.every((t) => t.state == TileState.present), isTrue);
    });

    test('T04 — letra duplicada não marca amarelo a mais', () {
      final r = evaluateGuess('TOROO', 'TERMO');
      final marcadas = r.where((t) => t.letter == 'O')
          .where((t) => t.state == TileState.correct || t.state == TileState.present);
      expect(marcadas.length, equals(1));
    });

    test('T05 — retorna exatamente 5 tiles', () {
      expect(evaluateGuess('CARRO', 'METRO').length, equals(5));
    });

    test('T06 — tiles carregam as letras corretas', () {
      final r = evaluateGuess('PRATO', 'METRO');
      expect(r[0].letter, 'P');
      expect(r[4].letter, 'O');
    });
  });

  group('GameController — estado da partida', () {
    late GameController c;
    late MockWordValidator v;

    setUp(() {
      c = GameController(answer: 'METRO');
      v = MockWordValidator();
    });
    tearDown(() => c.dispose());

    test('T07 — digitar adiciona letra ao chute', () {
      c.onLetterTyped('M');
      expect(c.currentGuess, equals('M'));
    });

    test('T08 — entrada minúscula vira maiúscula', () {
      c.onLetterTyped('m');
      expect(c.currentGuess, equals('M'));
    });

    test('T09 — não ultrapassa 5 letras', () {
      for (var i = 0; i < 8; i++) c.onLetterTyped('A');
      expect(c.currentGuess.length, equals(5));
    });

    test('T10 — backspace remove última letra', () {
      c.onLetterTyped('M');
      c.onLetterTyped('E');
      c.onBackspace();
      expect(c.currentGuess, equals('M'));
    });

    test('T11 — backspace em vazio não causa erro', () {
      expect(() => c.onBackspace(), returnsNormally);
    });

    test('T12 — palavra incompleta retorna erro', () {
      c.onLetterTyped('M');
      expect(c.submitGuess((_) => true), equals('Palavra incompleta'));
    });

    test('T13 — palavra inválida retorna erro (mock)', () {
      'CARRO'.split('').forEach(c.onLetterTyped);
      when(v('CARRO')).thenReturn(false);
      expect(c.submitGuess(v), equals('Palavra não reconhecida'));
      verify(v('CARRO')).called(1);
    });

    test('T14 — palavra válida limpa currentGuess', () {
      'CARRO'.split('').forEach(c.onLetterTyped);
      when(v('CARRO')).thenReturn(true);
      expect(c.submitGuess(v), isNull);
      expect(c.currentGuess, equals(''));
    });

    test('T15 — acertar a palavra leva a won', () {
      'METRO'.split('').forEach(c.onLetterTyped);
      when(v('METRO')).thenReturn(true);
      c.submitGuess(v);
      expect(c.status, equals(GameStatus.won));
    });

    test('T16 — 6 erros levam a lost', () {
      for (final chute in ['CARRO', 'PORTA', 'LIVRO', 'FESTA', 'NOITE', 'VERDE']) {
        chute.split('').forEach(c.onLetterTyped);
        when(v(chute)).thenReturn(true);
        c.submitGuess(v);
      }
      expect(c.status, equals(GameStatus.lost));
    });

    test('T17 — reiniciar zera tudo', () {
      'METRO'.split('').forEach(c.onLetterTyped);
      when(v('METRO')).thenReturn(true);
      c.submitGuess(v);
      c.reiniciar(answer: 'CASAL');
      expect(c.status, equals(GameStatus.playing));
      expect(c.currentGuess, equals(''));
      expect(c.currentRow, equals(0));
    });

    test('T18 — board começa com tiles vazias', () {
      for (final row in c.board) {
        for (final tile in row) {
          expect(tile.state, TileState.empty);
          expect(tile.letter, equals(''));
        }
      }
    });
  });

  group('Palavras e datas', () {
    test('T19 — palavraDoDia pertence à lista e tem 5 letras', () {
      final p = palavraDoDia(palavrasGabarito);
      expect(palavrasGabarito.contains(p), isTrue);
      expect(p.length, equals(5));
    });

    test('T20 — palavraAleatoria pertence à lista', () {
      expect(palavrasGabarito.contains(palavraAleatoria(palavrasGabarito)), isTrue);
    });

    test('T21 — hojeISO formato YYYY-MM-DD', () {
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(hojeISO()), isTrue);
    });
  });

  group('Score Service — Firestore simulado', () {
    test('T22 — primeira vitória grava pontuação correta', () async {
      final db  = FakeFirebaseFirestore();
      final ref = db.collection('usuarios').doc('uid-teste');
      final hoje = hojeISO();
      await db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final mesmoDia = snap.exists && snap.data()?['dataPontuacao'] == hoje;
        mesmoDia
            ? tx.update(ref, {'pontuacao': snap.data()!['pontuacao'] + 50})
            : tx.set(ref, {'pontuacao': 50, 'dataPontuacao': hoje}, SetOptions(merge: true));
      });
      expect((await ref.get()).data()?['pontuacao'], equals(50));
    });

    test('T23 — segunda vitória no mesmo dia acumula', () async {
      final db  = FakeFirebaseFirestore();
      final ref = db.collection('usuarios').doc('uid-teste');
      final hoje = hojeISO();
      await ref.set({'pontuacao': 50, 'dataPontuacao': hoje});
      await db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final mesmoDia = snap.exists && snap.data()?['dataPontuacao'] == hoje;
        mesmoDia
            ? tx.update(ref, {'pontuacao': snap.data()!['pontuacao'] + 40})
            : tx.set(ref, {'pontuacao': 40, 'dataPontuacao': hoje}, SetOptions(merge: true));
      });
      expect((await ref.get()).data()?['pontuacao'], equals(90));
    });

    test('T24 — vitória em dia novo reseta pontuação', () async {
      final db  = FakeFirebaseFirestore();
      final ref = db.collection('usuarios').doc('uid-teste');
      final hoje = hojeISO();
      await ref.set({'pontuacao': 60, 'dataPontuacao': '2000-01-01'});
      await db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final mesmoDia = snap.exists && snap.data()?['dataPontuacao'] == hoje;
        mesmoDia
            ? tx.update(ref, {'pontuacao': snap.data()!['pontuacao'] + 60})
            : tx.set(ref, {'pontuacao': 60, 'dataPontuacao': hoje}, SetOptions(merge: true));
      });
      expect((await ref.get()).data()?['dataPontuacao'], equals(hoje));
    });
  });
}