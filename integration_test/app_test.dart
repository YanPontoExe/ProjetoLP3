// integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tremapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integração — Tela de Login', () {
    testWidgets('T01 — campos de login aparecem na tela', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('T02 — botão Registrar navega para tela de registro', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(find.text('REGISTRO'), findsOneWidget);
    });

    testWidgets('T03 — login com campos vazios mostra erro', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('Integração — Tela de Jogo', () {
    testWidgets('T04 — campo de digitação aparece na tela do jogo', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navega direto para /home simulando usuário logado
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushReplacementNamed('/home');
      await tester.pumpAndSettle();

      expect(find.text('Digite sua palavra'), findsOneWidget);
    });

    testWidgets('T05 — digitar palavra preenche o tabuleiro', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushReplacementNamed('/home');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'METRO');
      await tester.pumpAndSettle();

      expect(find.text('M'), findsWidgets);
      expect(find.text('E'), findsWidgets);
    });

    testWidgets('T06 — navbar aparece com 3 botões', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushReplacementNamed('/home');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });

  group('Integração — Tela de Ranking', () {
    testWidgets('T07 — tela de ranking abre ao tocar no ícone', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushReplacementNamed('/home');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.leaderboard));
      await tester.pumpAndSettle();

      expect(find.text('RANKING'), findsOneWidget);
    });
  });
}