# Plano de Implementação — Lógica do Jogo (TERMO)

Documento de planejamento da implementação da lógica do jogo no projeto **M.E.T.R.O.** (clone do TERMO em Flutter + Firebase).

> Status do código analisado: branch `inicioTelaJogo`, commit base `b36b61f`.

---

## 1. Diagnóstico do estado atual

### O que já existe e funciona
| Arquivo | Responsabilidade | Estado |
|---|---|---|
| [lib/main.dart](lib/main.dart) | Bootstrap Firebase + `runApp` | OK |
| [lib/app.dart](lib/app.dart) | `MaterialApp` + rotas nomeadas | Funciona, mas com bug de rota |
| [lib/home.dart](lib/home.dart) | Shell (AppBar + PageView + navbar) | OK |
| [lib/login.dart](lib/login.dart) / [lib/registro.dart](lib/registro.dart) | Auth + criação de doc no Firestore | OK |
| [lib/widgets/quadroJogo.dart](lib/widgets/quadroJogo.dart) | `BoardUiWidget`, `UiTile`, `TileState` (UI pura, stateless) | **Excelente — reaproveitar 100%** |
| [lib/widgets/navbar.dart](lib/widgets/navbar.dart) | Navbar circular | OK |
| [lib/ranking.dart](lib/ranking.dart) | Placeholder | Vazio |
| [lib/game_screen.dart](lib/game_screen.dart) | Tela do jogo | Só esqueleto visual, **sem lógica** |

### Problemas a corrigir antes de começar
1. **Variável global `inputGuess`** em [lib/game_screen.dart:6](lib/game_screen.dart#L6) — estado tem que ser local ao widget (ou a um controller). Globais quebram hot-reload, testes e múltiplas instâncias.
2. **Rota `/game`** em [lib/app.dart:18](lib/app.dart#L18) aponta para `GameScreen` (que não tem AppBar nem navbar). O fluxo correto após login/registro deveria ser para `Home` (o shell). Hoje [lib/registro.dart:34](lib/registro.dart#L34) envia para `/game` direto e o usuário perde a navegação.
3. **Sem fonte de palavras**: não há lista de gabaritos nem de palavras válidas em lugar nenhum.
4. **Sem separação de camadas**: lógica, modelos e UI estão pendurados juntos.

---

## 2. Arquitetura recomendada

### Padrão: **Feature-first + MVC leve**

Não precisa Bloc nem Provider neste projeto — o escopo é pequeno. Recomendo **`ChangeNotifier` nativo do Flutter** com `AnimatedBuilder`/`ListenableBuilder` (zero dependência extra) ou simplesmente `setState` se a equipe preferir. O `ChangeNotifier` é só uma classe que avisa quando muda — mais fácil de testar isoladamente do que `setState`.

```
lib/
├── main.dart
├── app.dart
├── features/
│   ├── auth/
│   │   ├── login.dart                    ← move login.dart pra cá
│   │   └── registro.dart                 ← move registro.dart pra cá
│   ├── game/
│   │   ├── models/
│   │   │   ├── tile.dart                 ← UiTile + TileState (vem de quadroJogo.dart)
│   │   │   └── game_status.dart          ← enum playing / won / lost
│   │   ├── logic/
│   │   │   ├── guess_evaluator.dart      ← ★ CORAÇÃO: colore uma tentativa
│   │   │   └── game_controller.dart      ← ChangeNotifier que mantém o estado
│   │   ├── data/
│   │   │   ├── palavras_gabarito.dart    ← lista de palavras-resposta
│   │   │   └── palavras_validas.dart     ← lista de palavras aceitas como chute
│   │   ├── services/
│   │   │   ├── word_provider.dart        ← sorteia/escolhe a palavra do dia
│   │   │   └── score_service.dart        ← grava pontuação no Firestore
│   │   ├── widgets/
│   │   │   ├── board_widget.dart         ← era quadroJogo.dart (renomear)
│   │   │   └── game_over_dialog.dart     ← popup de fim de jogo
│   │   └── game_screen.dart
│   ├── home/
│   │   └── home.dart
│   └── ranking/
│       └── ranking_screen.dart
└── shared/
    ├── widgets/
    │   └── navbar.dart
    └── theme/
        └── app_colors.dart               ← centraliza as cores RGBO repetidas
```

Os arquivos atuais continuam funcionando se a equipe não quiser mover tudo — a árvore acima é a meta. **Mover é opcional; separar lógica de UI é obrigatório.**

---

## 3. Modelo de domínio

```dart
// features/game/models/game_status.dart
enum GameStatus { playing, won, lost }

// features/game/models/tile.dart  (a refatorar a partir de quadroJogo.dart)
enum TileState { empty, filled, correct, present, absent }

class UiTile {
  final String letter;
  final TileState state;
  const UiTile({required this.letter, this.state = TileState.empty});
}
```

O `UiTile` já está pronto em [lib/widgets/quadroJogo.dart](lib/widgets/quadroJogo.dart) — só precisa ser extraído.

---

## 4. O coração do jogo: algoritmo de coloração

**Esse é o ponto mais sutil.** A maioria das implementações erra com letras repetidas. Ex.: gabarito `"BOLAR"`, chute `"BOBOS"`. O primeiro `B` é verde, o segundo `B` deveria ser cinza (não amarelo, porque já “gastamos” o único B do gabarito).

### Algoritmo correto em **dois passos**

```dart
// features/game/logic/guess_evaluator.dart
List<UiTile> evaluateGuess(String guess, String answer) {
  assert(guess.length == answer.length);

  final result = List<UiTile>.filled(answer.length, const UiTile(letter: ''));
  final answerChars = answer.split('');           // pool mutável
  final guessChars  = guess.split('');

  // Passo 1: marca todos os verdes (correct) e "consome" do pool
  for (var i = 0; i < guessChars.length; i++) {
    if (guessChars[i] == answerChars[i]) {
      result[i] = UiTile(letter: guessChars[i], state: TileState.correct);
      answerChars[i] = '';     // consumido
      guessChars[i]  = '';     // já tratado
    }
  }

  // Passo 2: marca amarelos (present) e cinzas (absent), respeitando o pool
  for (var i = 0; i < guessChars.length; i++) {
    if (guessChars[i].isEmpty) continue;     // já foi verde

    final idx = answerChars.indexOf(guessChars[i]);
    if (idx >= 0) {
      result[i] = UiTile(letter: guessChars[i], state: TileState.present);
      answerChars[idx] = '';                 // consome do pool
    } else {
      result[i] = UiTile(letter: guessChars[i], state: TileState.absent);
    }
  }

  return result;
}
```

Essa função é **pura** (sem efeito colateral, sem Flutter) → fácil de testar com `flutter test`.

---

## 5. Controller (estado do jogo)

```dart
// features/game/logic/game_controller.dart
class GameController extends ChangeNotifier {
  static const int wordLength  = 5;
  static const int maxAttempts = 6;

  final String _answer;             // injetada pelo WordProvider
  final List<List<UiTile>> _board = [];
  String _currentGuess = '';
  GameStatus _status = GameStatus.playing;

  GameController({required String answer}) : _answer = answer {
    _board.addAll(List.generate(
      maxAttempts,
      (_) => List.generate(wordLength, (_) => const UiTile(letter: '')),
    ));
  }

  List<List<UiTile>> get board => _board;
  GameStatus get status => _status;
  int get currentRow => _board.indexWhere(
    (row) => row.every((t) => t.state == TileState.empty),
  );

  void onLetterTyped(String letter) {
    if (_status != GameStatus.playing) return;
    if (_currentGuess.length >= wordLength) return;
    _currentGuess += letter.toUpperCase();
    _redrawCurrentRow();
    notifyListeners();
  }

  void onBackspace() {
    if (_currentGuess.isEmpty) return;
    _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
    _redrawCurrentRow();
    notifyListeners();
  }

  /// Retorna mensagem de erro (ou null se sucesso) — UI mostra como SnackBar.
  String? submitGuess(bool Function(String) isValidWord) {
    if (_currentGuess.length != wordLength) return 'Palavra incompleta';
    if (!isValidWord(_currentGuess))         return 'Palavra não reconhecida';

    final row = currentRow;
    _board[row] = evaluateGuess(_currentGuess, _answer);

    if (_currentGuess == _answer) {
      _status = GameStatus.won;
    } else if (row == maxAttempts - 1) {
      _status = GameStatus.lost;
    }

    _currentGuess = '';
    notifyListeners();
    return null;
  }

  void _redrawCurrentRow() {
    final row = currentRow;
    if (row < 0) return;
    for (var i = 0; i < wordLength; i++) {
      _board[row][i] = i < _currentGuess.length
        ? UiTile(letter: _currentGuess[i], state: TileState.filled)
        : const UiTile(letter: '');
    }
  }
}
```

**Por que `ChangeNotifier`:** desacopla a lógica do widget → permite testes unitários da regra do jogo sem subir UI (`flutter test`, não `flutter test --integration`).

---

## 6. Fonte de palavras

### Opções (em ordem de complexidade)

| Opção | Onde fica | Quando usar |
|---|---|---|
| **A. Lista hardcoded em `.dart`** | `data/palavras_gabarito.dart` | Protótipo / MVP |
| **B. Arquivo `assets/`** | `assets/palavras.txt` lido com `rootBundle` | Centenas/milhares de palavras |
| **C. Firestore** | coleção `palavras` | Quando quiser “palavra do dia” global e atualizável remotamente |

**Recomendação:** começar com **A** (10-20 palavras hardcoded) → migrar para **B** quando passar dos 50 → considerar **C** só se quiser palavra do dia compartilhada.

### Palavra do dia (determinística)

Para que todo mundo jogue a mesma palavra no mesmo dia (e dê pra ter ranking diário):

```dart
String palavraDoDia(List<String> pool) {
  final hoje = DateTime.now();
  final epoch = DateTime(2026, 1, 1);
  final dias = hoje.difference(epoch).inDays;
  return pool[dias % pool.length];
}
```

---

## 7. Integração com a UI atual

A [game_screen.dart](lib/game_screen.dart) precisa virar isto (esqueleto):

```dart
class _GameScreenState extends State<GameScreen> {
  late final GameController controller;

  @override
  void initState() {
    super.initState();
    controller = GameController(answer: palavraDoDia(palavrasGabarito));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BoardUiWidget(board: controller.board),
          _InputField(controller: controller),  // submete via Enter
          if (controller.status != GameStatus.playing)
            _GameOverBanner(status: controller.status),
        ],
      ),
    );
  }
}
```

O **`TextField` atual pode continuar** como input (mais simples), mas tem dois caminhos:

- **Caminho rápido (recomendado p/ MVP):** manter `TextField` com `onChanged` chamando `controller.onLetterTyped` e `onSubmitted` chamando `controller.submitGuess`.
- **Caminho “fiel ao Termo”:** construir um teclado virtual (`KeyboardWidget`) na parte de baixo da tela, com letras coloridas conforme o que já foi descoberto.

---

## 8. Integração com Firestore

Após `status == won`, atualizar pontuação:

```dart
// features/game/services/score_service.dart
Future<void> registrarVitoria({required int tentativas}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final pontos = (7 - tentativas) * 10; // ex.: 60 pts se acertou na 1ª, 10 na 6ª
  await FirebaseFirestore.instance
    .collection('usuarios')
    .doc(user.uid)
    .update({'pontuacao': FieldValue.increment(pontos)});
}
```

Já existe o doc do usuário criado em [lib/registro.dart:22](lib/registro.dart#L22) — só somar.

---

## 9. Ordem de implementação (passo a passo)

Sugiro fazer em PRs pequenos, cada um testável:

### **PR 1 — Limpeza preparatória** (sem nova feature)
- [ ] Remover variável global `inputGuess` de [game_screen.dart](lib/game_screen.dart)
- [ ] Corrigir rota em [registro.dart:34](lib/registro.dart#L34): trocar `/game` por `/home`
- [ ] Corrigir rota em [app.dart:18](lib/app.dart#L18): remover ou apontar `/game` para `Home`
- [ ] (opcional) Criar `shared/theme/app_colors.dart` e substituir as `Color.fromRGBO(...)` espalhadas

### **PR 2 — Modelo + algoritmo (sem UI)**
- [ ] Criar `features/game/models/tile.dart` movendo `UiTile` e `TileState` de [quadroJogo.dart](lib/widgets/quadroJogo.dart)
- [ ] Criar `features/game/models/game_status.dart`
- [ ] Criar `features/game/logic/guess_evaluator.dart` com `evaluateGuess()`
- [ ] **Escrever testes** em `test/guess_evaluator_test.dart` cobrindo:
  - acerto total
  - todas erradas
  - letras duplicadas no chute
  - letras duplicadas no gabarito
  - mistura de verde + amarelo + cinza com duplicatas

### **PR 3 — Controller + lista de palavras**
- [ ] Criar `data/palavras_gabarito.dart` com 10-20 palavras
- [ ] Criar `services/word_provider.dart` (palavra do dia)
- [ ] Criar `logic/game_controller.dart`
- [ ] Testes do controller (digitar, apagar, submeter, vitória, derrota)

### **PR 4 — Plugar UI no controller**
- [ ] Refatorar [game_screen.dart](lib/game_screen.dart) para usar `GameController` + `ListenableBuilder`
- [ ] Ajustar `BoardUiWidget` (renomear arquivo para `board_widget.dart`)
- [ ] Mostrar feedback de fim de jogo (dialog ou banner)
- [ ] Reiniciar partida (botão “Jogar de novo” pega outra palavra)

### **PR 5 — Firestore + ranking**
- [ ] Criar `services/score_service.dart` com `registrarVitoria()`
- [ ] Chamar `registrarVitoria` ao vencer
- [ ] Popular [ranking.dart](lib/ranking.dart) com `StreamBuilder` em `usuarios` ordenado por `pontuacao desc`

### **PR 6 — Polimento (opcional)**
- [ ] Teclado virtual com letras coloridas
- [ ] Animações de flip nas tiles (`AnimatedRotation` / `AnimatedSwitcher`)
- [ ] Persistir partida do dia (não deixar trapacear recarregando) — usar `shared_preferences`
- [ ] Modo “palavras com acento” (normalizar com `removeDiacritics`)

---

## 10. Decisões de design recomendadas

| Tema | Recomendação | Por quê |
|---|---|---|
| Gerenciamento de estado | `ChangeNotifier` nativo | Sem dependências extras, fácil de testar |
| Maiusculização | Forçar `toUpperCase()` no controller | Evita comparar `"casa"` com `"CASA"` |
| Acentos | Normalizar gabarito e chute via `String.replaceAll` ou pacote `diacritic` | TERMO BR usa palavras sem acento na UI |
| Validação de chute | Lista “válidas” > lista “gabarito” | Aceita mais palavras como tentativa do que como resposta |
| Palavra do dia | Determinística por data | Permite ranking justo |
| Pontuação | `(7 - tentativas) * 10` | Recompensa acerto rápido sem zerar quem demora |

---

## 11. Onde começar agora (sessão 1)

Se eu fosse começar hoje:

1. **PR 1 inteiro** (15 min — limpeza)
2. Criar **`guess_evaluator.dart` + testes** (PR 2 parcial — 30-40 min)
3. Validar com `flutter test` antes de tocar em qualquer UI

A regra de ouro: **a lógica do jogo nunca depende do Flutter**. Se o `evaluateGuess` precisar de `BuildContext` ou `setState`, algo está errado.

---

## 12. Riscos e armadilhas

- **Letras repetidas (item 4)** — testar exaustivamente. É o bug mais comum em clones de Wordle.
- **Acentos** — `"CAFÉ"` vs `"CAFE"`. Decidir uma política e aplicar nos dois lados (gabarito e chute).
- **Hot-reload + variáveis globais** — outra razão para matar `inputGuess` global.
- **PageView preserva estado da aba** — quando o usuário vai pra aba ranking e volta, o `GameController` precisa sobreviver. Como o `Home` mantém `GameScreen` vivo dentro do `PageView`, isso já funciona automaticamente. Só fica atento se um dia trocar para `IndexedStack` ou similar.
- **Firestore offline** — `score_service` deve tolerar falha de rede (já há try/catch nos outros lugares — manter padrão).
