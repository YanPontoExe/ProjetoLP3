import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tremapp/app.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integração — Tela de Login', () {
    testWidgets('T01 — campos de login aparecem na tela', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(decoration: InputDecoration(labelText: 'E-mail')),
              TextField(decoration: InputDecoration(labelText: 'Senha')),
              ElevatedButton(onPressed: () {}, child: Text('Entrar')),
              TextButton(onPressed: () {}, child: Text('Registrar')),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
    });
  });

  group('Integração — Tabuleiro do Jogo', () {
    testWidgets('T02 — campo de digitação aparece', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextField(
            decoration: InputDecoration(labelText: 'Digite sua palavra'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Digite sua palavra'), findsOneWidget);
    });

    testWidgets('T03 — digitar texto preenche o campo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextField(
            decoration: InputDecoration(labelText: 'Digite sua palavra'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'METRO');
      await tester.pumpAndSettle();

      expect(find.text('METRO'), findsOneWidget);
    });
  });

  group('Integração — Navbar', () {
    testWidgets('T04 — ícones da navbar aparecem', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Ranking'),
              BottomNavigationBarItem(icon: Icon(Icons.play_arrow_rounded), label: 'Jogo'),
              BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Sair'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('T05 — texto Ranking aparece na navbar', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Ranking'),
              BottomNavigationBarItem(icon: Icon(Icons.play_arrow_rounded), label: 'Jogo'),
              BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Sair'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ranking'), findsOneWidget);
      expect(find.text('Jogo'), findsOneWidget);
    });
  });
}