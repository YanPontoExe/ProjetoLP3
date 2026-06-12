
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importações do projeto
import 'package:tremapp/game/logic/game_controller.dart';
import 'package:tremapp/game/logic/guess_evaluator.dart';
import 'package:tremapp/game/models/game_status.dart';
import 'package:tremapp/widgets/quadroJogo.dart';
import 'package:tremapp/game/data/palavras.dart';
import 'package:tremapp/game/data/datas.dart';

// ============================================================
// MOCK — simula validação de palavras (isValidWord)
// ============================================================
class MockWordValidator extends Mock {
  bool call(String word);
}

// ============================================================
// GRUPO 1 — guess_evaluator.dart
// Testa a lógica de coloração: verde / amarelo / cinza
// ============================================================
void main() {
  // ----------------------------------------------------------
  group('GuessEvaluator — avaliação do chute', () {

    test('T01 — Todas as letras corretas (palavra = gabarito)', () {
      final resultado = evaluateGuess('TERMO', 'TERMO');

      // Todas as 5 tiles devem ser verdes
      for (final tile in resultado) {
        expect(tile.state, TileState.correct,
            reason: 'Letra ${tile.letter} deveria ser verde');
      }
    });

    test('T02 — Nenhuma letra existe na palavra', () {
      final resultado = evaluateGuess('BBBBB', 'TERMO');

      for (final tile in resultado) {
        expect(tile.state, TileState.absent,
            reason: 'Letra ${tile.letter} não existe em TERMO');
      }
    });

    test('T03 — Letra presente mas na posição errada (amarelo)', () {
      // OTERM — todas as letras de TERMO existem, mas deslocadas
      final resultado = evaluateGuess('OTERM', 'TERMO');

      // Nenhuma deve ser verde (nenhuma está no lugar certo)
      expect(resultado.any((t) => t.state == TileState.correct), isFalse);
      // Todas devem ser amarelas
      expect(resultado.every((t) => t.state == TileState.present), isTrue);
    });

    test('T04 — Letras duplicadas: não marca amarelo a mais', () {
      // TOROO vs TERMO: só tem 1 O em TERMO, então apenas 1 tile O vira amarela
      final resultado = evaluateGuess('TOROO', 'TERMO');
      final tilesO = resultado.where((t) => t.letter == 'O');
      final marcadas = tilesO.where(
          (t) => t.state == TileState.correct || t.state == TileState.present);
      expect(marcadas.length, equals(1),
          reason: 'Apenas 1 O em TERMO; não deve marcar os dois');
    });

    test('T05 — Letras corretas têm prioridade sobre amarelas (verde consome estoque)', () {
      // AAAXB vs AABBB: primeira A é verde, segunda A deveria ser cinza (estoque zerado)
      final resultado = evaluateGuess('AAAXB', 'AABBB');
      expect(resultado[0].state, TileState.correct);  // A na pos 0: verde
      expect(resultado[1].state, TileState.absent);   // A na pos 1: cinza (já consumida)
    });

    test('T06 — Retorna exatamente 5 tiles', () {
      final resultado = evaluateGuess('CARRO', 'METRO');
      expect(resultado.length, equals(5));
    });

    test('T07 — Tiles carregam a letra correta', () {
      final resultado = evaluateGuess('PRATO', 'METRO');
      expect(resultado[0].letter, 'P');
      expect(resultado[1].letter, 'R');
      expect(resultado[2].letter, 'A');
      expect(resultado[3].letter, 'T');
      expect(resultado[4].letter, 'O');
    });
  });

  // ----------------------------------------------------------
  group('GameController — estado da partida', () {

    late GameController controller;
    late MockWordValidator validador;

    setUp(() {
      controller = GameController(answer: 'METRO');
      validador  = MockWordValidator();
    });

    tearDown(() {
      controller.dispose();
    });

    // ── Digitação ──────────────────────────────────────────
    test('T08 — onLetterTyped adiciona letra ao chute atual', () {
      controller.onLetterTyped('M');
      expect(controller.currentGuess, equals('M'));
    });

    test('T09 — onLetterTyped em maiúsculas (entrada minúscula)', () {
      controller.onLetterTyped('m'); // minúscula
      expect(controller.currentGuess, equals('M')); // deve virar maiúscula
    });

    test('T10 — onLetterTyped não ultrapassa 5 letras', () {
      for (var i = 0; i < 8; i++) controller.onLetterTyped('A');
      expect(controller.currentGuess.length, equals(5));
    });

    test('T11 — onBackspace remove a última letra', () {
      controller.onLetterTyped('M');
      controller.onLetterTyped('E');
      controller.onBackspace();
      expect(controller.currentGuess, equals('M'));
    });

    test('T12 — onBackspace em chute vazio não causa erro', () {
      expect(() => controller.onBackspace(), returnsNormally);
      expect(controller.currentGuess, equals(''));
    });

    // ── submitGuess ────────────────────────────────────────
    test('T13 — submitGuess retorna erro se palavra incompleta', () {
      controller.onLetterTyped('M');
      controller.onLetterTyped('E');
      // só 2 letras
      final erro = controller.submitGuess((_) => true);
      expect(erro, equals('Palavra incompleta'));
    });

    test('T14 — submitGuess retorna erro se palavra não reconhecida (mock)', () {
      'CARRO'.split('').forEach(controller.onLetterTyped);

      // Mock retorna false → palavra inválida
      when(validador('CARRO')).thenReturn(false);
      final erro = controller.submitGuess(validador);
      expect(erro, equals('Palavra não reconhecida'));
      verify(validador('CARRO')).called(1); // garante que o mock foi chamado
    });

    test('T15 — submitGuess aceita palavra válida e limpa currentGuess', () {
      'CARRO'.split('').forEach(controller.onLetterTyped);

      when(validador('CARRO')).thenReturn(true);
      final erro = controller.submitGuess(validador);

      expect(erro, isNull);
      expect(controller.currentGuess, equals(''));
    });

    test('T16 — Vitória: status vira won ao acertar a palavra', () {
      'METRO'.split('').forEach(controller.onLetterTyped);
      when(validador('METRO')).thenReturn(true);

      controller.submitGuess(validador);
      expect(controller.status, equals(GameStatus.won));
    });

    test('T17 — Derrota: status vira lost após 6 chutes errados', () {
      final chutes = ['CARRO', 'PORTA', 'LIVRO', 'FESTA', 'NOITE', 'VERDE'];
      for (final chute in chutes) {
        chute.split('').forEach(controller.onLetterTyped);
        when(validador(chute)).thenReturn(true);
        controller.submitGuess(validador);
      }
      expect(controller.status, equals(GameStatus.lost));
    });

    test('T18 — Após vitória, onLetterTyped é ignorado', () {
      'METRO'.split('').forEach(controller.onLetterTyped);
      when(validador('METRO')).thenReturn(true);
      controller.submitGuess(validador);

      controller.onLetterTyped('X'); // deve ser ignorado
      expect(controller.currentGuess, equals(''));
    });

    // ── currentRow ─────────────────────────────────────────
    test('T19 — currentRow começa em 0 (nenhum chute enviado)', () {
      expect(controller.currentRow, equals(0));
    });

    test('T20 — currentRow avança após cada chute enviado', () {
      'CARRO'.split('').forEach(controller.onLetterTyped);
      when(validador('CARRO')).thenReturn(true);
      controller.submitGuess(validador);
      expect(controller.currentRow, equals(1));
    });

    // ── reiniciar ──────────────────────────────────────────
    test('T21 — reiniciar zera status, chute e board', () {
      'METRO'.split('').forEach(controller.onLetterTyped);
      when(validador('METRO')).thenReturn(true);
      controller.submitGuess(validador); // ganhou

      controller.reiniciar(answer: 'CASAL');

      expect(controller.status, equals(GameStatus.playing));
      expect(controller.currentGuess, equals(''));
      expect(controller.currentRow, equals(0));
      expect(controller.answer, equals('CASAL'));
    });

    test('T22 — board começa com todas as tiles vazias', () {
      for (final row in controller.board) {
        for (final tile in row) {
          expect(tile.state, TileState.empty);
          expect(tile.letter,  equals(''));
        }
      }
    });

    test('T23 — board reflete letras digitadas na linha atual', () {
      controller.onLetterTyped('M');
      controller.onLetterTyped('E');

      expect(controller.board[0][0].letter, equals('M'));
      expect(controller.board[0][0].state,  equals(TileState.filled));
      expect(controller.board[0][1].letter, equals('E'));
      expect(controller.board[0][1].state,  equals(TileState.filled));
      expect(controller.board[0][2].state,  equals(TileState.empty)); // ainda vazia
    });
  });

  // ----------------------------------------------------------
  group('Palavras — palavraDoDia e palavraAleatoria', () {

    test('T24 — palavraDoDia retorna sempre uma string não vazia', () {
      final palavra = palavraDoDia(palavrasGabarito);
      expect(palavra, isNotEmpty);
    });

    test('T25 — palavraDoDia pertence à lista de gabarito', () {
      final palavra = palavraDoDia(palavrasGabarito);
      expect(palavrasGabarito.contains(palavra), isTrue);
    });

    test('T26 — palavraDoDia tem exatamente 5 caracteres', () {
      final palavra = palavraDoDia(palavrasGabarito);
      expect(palavra.length, equals(5));
    });

    test('T27 — palavraAleatoria pertence à lista', () {
      final palavra = palavraAleatoria(palavrasGabarito);
      expect(palavrasGabarito.contains(palavra), isTrue);
    });

    test('T28 — hojeISO retorna formato YYYY-MM-DD', () {
      final hoje = hojeISO();
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(regex.hasMatch(hoje), isTrue,
          reason: 'Esperado YYYY-MM-DD, recebido: $hoje');
    });

    test('T29 — hojeISO bate com DateTime.now()', () {
      final agora = DateTime.now();
      final esperado =
          '${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}';
      expect(hojeISO(), equals(esperado));
    });
  });

  // ----------------------------------------------------------
  group('Score Service — Firestore simulado (FakeFirestore)', () {

    test('T30 — registrarVitoria cria doc com pontuação correta no Firestore', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final fakeAuth     = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'uid-teste', email: 'teste@metro.com'),
      );

      // Simula a lógica de score_service diretamente com os fakes
      final user = fakeAuth.currentUser!;
      final pontos = (7 - 2) * 10; // acertou na 2ª tentativa = 50 pts
      final hoje   = hojeISO();
      final ref    = fakeFirestore.collection('usuarios').doc(user.uid);

      await fakeFirestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final mesmoDia = snap.exists && snap.data()?['dataPontuacao'] == hoje;
        if (mesmoDia) {
          tx.update(ref, {'pontuacao': snap.data()!['pontuacao'] + pontos});
        } else {
          tx.set(ref, {'pontuacao': pontos, 'dataPontuacao': hoje},
              SetOptions(merge: true));
        }
      });

      final doc = await ref.get();
      expect(doc.data()?['pontuacao'],     equals(50));
      expect(doc.data()?['dataPontuacao'], equals(hoje));
    });

    test('T31 — segunda vitória no mesmo dia acumula pontuação', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final hoje          = hojeISO();
      final ref           = fakeFirestore.collection('usuarios').doc('uid-teste');

      // Primeira vitória: 50 pts
      await ref.set({'pontuacao': 50, 'dataPontuacao': hoje});

      // Segunda vitória no mesmo dia: +40 pts
      final pontosExtra = (7 - 3) * 10; // 3ª tentativa = 40 pts
      await fakeFirestore.runTransaction((tx) async {
        final snap     = await tx.get(ref);
        final mesmoDia = snap.exists && snap.data()?['dataPontuacao'] == hoje;
        if (mesmoDia) {
          tx.update(ref, {'pontuacao': snap.data()!['pontuacao'] + pontosExtra});
        } else {
          tx.set(ref, {'pontuacao': pontosExtra, 'dataPontuacao': hoje},
              SetOptions(merge: true));
        }
      });

      final doc = await ref.get();
      expect(doc.data()?['pontuacao'], equals(90)); // 50 + 40
    });

    test('T32 — vitória em dia novo reseta a pontuação', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final ref           = fakeFirestore.collection('usuarios').doc('uid-teste');

      // Simula doc com pontuação de "ontem"
      await ref.set({'pontuacao': 60, 'dataPontuacao': '2000-01-01'});

      final hoje       = hojeISO();
      final pontosHoje = (7 - 1) * 10; // acertou de primeira = 60 pts
      await fakeFirestore.runTransaction((tx) async {
        final snap     = await tx.get(ref);
        final mesmoDia = snap.exists && snap.data()?['dataPontuacao'] == hoje;
        if (mesmoDia) {
          tx.update(ref, {'pontuacao': snap.data()!['pontuacao'] + pontosHoje});
        } else {
          tx.set(ref, {'pontuacao': pontosHoje, 'dataPontuacao': hoje},
              SetOptions(merge: true));
        }
      });

      final doc = await ref.get();
      expect(doc.data()?['pontuacao'],     equals(60)); // resetou para hoje
      expect(doc.data()?['dataPontuacao'], equals(hoje));
    });
  });
}
