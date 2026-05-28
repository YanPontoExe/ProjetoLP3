# Plano de Implementação — Lógica do Jogo (TERMO)

Guia para implementar a lógica do jogo no projeto **M.E.T.R.O.** (clone do TERMO em Flutter + Firebase).

> **Como usar:** a **Parte 1** explica o que existe, onde cada coisa vai morar e como a lógica funciona no geral — leia antes de codar. A **Parte 2** é o passo a passo: começa criando os arquivos, um por um, com o objetivo de cada um e a lógica explicada em português. Os trechos de Dart são esqueletos/dicas para você escrever o código — só o algoritmo de coloração (Passo 3) vem completo, porque é o ponto onde quase todo clone erra.

> Estado analisado: branch `main`, commit `b5b8674`.

---

# PARTE 1 — Entenda antes de codar

## 1. Objetivo

Sair de uma tela de jogo **só visual** para um jogo jogável:
- O jogador digita uma palavra de 5 letras e tem 6 tentativas.
- Cada tentativa pinta as letras: **verde** (posição certa), **amarelo** (existe mas em outro lugar), **cinza** (não existe).
- Ao acertar (ou esgotar as tentativas), o jogo termina e, na vitória, soma pontos no ranking que **já existe**.

## 2. Diagnóstico do estado atual (main)

### O que já funciona
| Arquivo | Responsabilidade | Estado |
|---|---|---|
| [lib/main.dart](lib/main.dart) | Bootstrap Firebase + `runApp` | OK |
| [lib/app.dart](lib/app.dart) | `MaterialApp` + rotas nomeadas | Funciona, com bug de rota |
| [lib/home.dart](lib/home.dart) | Shell (AppBar + PageView + navbar) | OK — abre na aba do jogo (`activeIndex = 1`) |
| [lib/login.dart](lib/login.dart) | Auth + navega p/ `/home` | OK |
| [lib/registro.dart](lib/registro.dart) | Cria doc do usuário no Firestore | OK, mas navega p/ `/game` (bug) |
| [lib/widgets/quadroJogo.dart](lib/widgets/quadroJogo.dart) | `BoardUiWidget`, `UiTile`, `TileState` (UI pura) | **Reaproveitar 100%** |
| [lib/widgets/navbar.dart](lib/widgets/navbar.dart) | Navbar circular | OK |
| [lib/ranking.dart](lib/ranking.dart) | Lista `usuarios` por `pontuacao desc` | **✅ JÁ FEITO** |
| [lib/game_screen.dart](lib/game_screen.dart) | Tela do jogo | Só esqueleto visual, **sem lógica** |

### Problemas a corrigir (entram no Passo 1)
1. **Global `inputGuess`** em [game_screen.dart:6](lib/game_screen.dart#L6) — estado tem que ser local. Global quebra hot-reload e testes.
2. **Rota `/game`** em [app.dart:18](lib/app.dart#L18) abre `GameScreen` sem AppBar/navbar; [registro.dart:34](lib/registro.dart#L34) usa ela e o usuário perde a navegação. O certo é ir p/ `/home`.
3. **Sem fonte de palavras.**

### Detalhes do projeto que vão te pegar
- O pacote chama-se `tremapp` → imports são `package:tremapp/...` (ou relativos).
- `UiTile` **não** tem construtor `const` ([quadroJogo.dart:30](lib/widgets/quadroJogo.dart#L30)). `const UiTile(letter: '')` **não compila** até você adicionar `const` ao construtor.
- Ainda **não existe pasta `test/`** — você cria quando chegar nos testes.

## 3. Estrutura de arquivos (onde tudo vai morar)

Não precisa Bloc nem Provider — use **`ChangeNotifier` nativo** (zero dependência extra). Mover os arquivos antigos é opcional; **separar lógica de UI é obrigatório**.

```
lib/
├── game_screen.dart                  ← refatorar p/ usar o controller (Passo 8)
├── ranking.dart                      ← pronto
├── widgets/quadroJogo.dart           ← UiTile / TileState / BoardUiWidget (já existe)
└── game/                             ← TUDO que você vai criar fica aqui
    ├── models/
    │   └── game_status.dart          ← Passo 2
    ├── logic/
    │   ├── guess_evaluator.dart      ← Passo 3 (coração)
    │   └── game_controller.dart      ← Passo 6
    ├── data/
    │   └── palavras.dart             ← Passo 5
    └── services/
        └── score_service.dart        ← Passo 9
```

**Regra de ouro:** os arquivos em `game/logic`, `game/models` e `game/data` **nunca** importam `package:flutter/material.dart`. Se a lógica precisar de `BuildContext` ou `setState`, algo está errado.

## 4. Como a lógica funciona (visão geral)

O fluxo, do toque na tela até a cor aparecer:

```
usuário digita  →  GameController guarda o que foi digitado
usuário envia   →  GameController chama evaluateGuess(chute, gabarito)
                       ↓
                   evaluateGuess devolve 5 tiles já coloridas
                       ↓
                   GameController grava na linha e chama notifyListeners()
                       ↓
                   a tela (ListenableBuilder) redesenha o BoardUiWidget
```

Três responsabilidades separadas:
- **`evaluateGuess`** (função pura) — recebe duas palavras, devolve as cores. Não sabe o que é tela.
- **`GameController`** (`ChangeNotifier`) — guarda o tabuleiro, a palavra digitada e o status (jogando/ganhou/perdeu); avisa quando muda.
- **`GameScreen`** (widget) — só lê o controller e desenha. Não calcula nada.

Essa separação é o que permite testar a regra do jogo sem abrir tela (`flutter test`).

---

# PARTE 2 — Passo a passo

> Sugestão: cada passo (ou par de passos) vira um PR pequeno e testável. Rode `flutter analyze` ao fim de cada um.

## Passo 1 — Limpeza preparatória

**Objetivo:** remover o que vai atrapalhar, antes de criar qualquer coisa nova.

1. Em [game_screen.dart](lib/game_screen.dart): apague a linha `var inputGuess = "";` (linha 6) e qualquer uso dela no `TextField`.
2. Em [registro.dart:34](lib/registro.dart#L34): troque `pushReplacementNamed('/game')` por `'/home'`.
3. Em [app.dart:18](lib/app.dart#L18): remova a rota `"/game"` (ou aponte-a para `const Home()`).

Ao terminar, o app ainda roda igual — só sem a global e sem o fluxo quebrado.

## Passo 2 — Criar `game/models/game_status.dart`

**Objetivo:** representar em que fase a partida está.

**Lógica:** três situações possíveis — jogando, ganhou, perdeu. Um `enum` resolve.

```dart
enum GameStatus { playing, won, lost }
```

> `TileState` e `UiTile` você **não precisa criar** — já existem em [quadroJogo.dart](lib/widgets/quadroJogo.dart). Se for usar `const UiTile(...)` no controller, adicione `const` ao construtor de `UiTile` agora.

## Passo 3 — Criar `game/logic/guess_evaluator.dart` (o coração)

**Objetivo:** dada uma palavra chutada e o gabarito, devolver as 5 tiles já coloridas.

**Por que isso é o passo mais delicado:** com letras repetidas, a conta ingênua erra. Gabarito `"BOLAR"`, chute `"BOBOS"`:
- O 1º `B` está na posição certa → **verde**.
- O 2º `B` (posição 3) não existe mais no gabarito (só tinha um B, e o verde já "gastou") → tem que ser **cinza**, não amarelo.

A solução: tratar o gabarito como um **estoque de letras** e ir **consumindo** conforme usa.

**A lógica em 2 passos:**

1. **Verdes primeiro.** Para cada posição `i`: se `chute[i] == gabarito[i]`, marque `correct` e **remova essa letra do estoque** (vire `''`). Faça isso para a linha toda antes do passo 2 — é o que dá prioridade aos verdes.
2. **Amarelos e cinzas no que sobrou.** Para cada posição ainda não resolvida: procure a letra no **estoque restante**. Achou → `present` (amarelo) e **consome** essa ocorrência; não achou → `absent` (cinza).

```dart
// game/logic/guess_evaluator.dart  — PURO, sem Flutter
import 'package:tremapp/widgets/quadroJogo.dart';

List<UiTile> evaluateGuess(String guess, String answer) {
  assert(guess.length == answer.length);

  final result      = List<UiTile>.filled(answer.length, UiTile(letter: ''));
  final answerChars = answer.split('');  // estoque mutável
  final guessChars  = guess.split('');

  // Passo 1 — verdes
  for (var i = 0; i < guessChars.length; i++) {
    if (guessChars[i] == answerChars[i]) {
      result[i]      = UiTile(letter: guessChars[i], state: TileState.correct);
      answerChars[i] = '';   // consumido
      guessChars[i]  = '';   // já tratado
    }
  }

  // Passo 2 — amarelos e cinzas
  for (var i = 0; i < guessChars.length; i++) {
    if (guessChars[i].isEmpty) continue;            // já era verde
    final idx = answerChars.indexOf(guessChars[i]);
    if (idx >= 0) {
      result[i]        = UiTile(letter: guessChars[i], state: TileState.present);
      answerChars[idx] = '';                        // consome do estoque
    } else {
      result[i] = UiTile(letter: guessChars[i], state: TileState.absent);
    }
  }
  return result;
}
```

## Passo 4 — Testar o evaluator

**Objetivo:** provar que a coloração está certa antes de plugar em qualquer tela.

1. Crie a pasta `test/` e o arquivo `test/guess_evaluator_test.dart`.
2. Escreva um `test(...)` para cada caso (use `expect` comparando o `state` de cada tile):
   - acerto total (`"CASA"`/`"CASA"` → tudo verde);
   - tudo errado (nenhuma letra em comum → tudo cinza);
   - letra repetida no **chute** mas única no gabarito (a 2ª vira cinza);
   - letra repetida no **gabarito**;
   - mistura verde + amarelo + cinza: o caso `"BOLAR"`/`"BOBOS"`.
3. Rode:

```bash
flutter test
```

Só passe para o Passo 5 com tudo verde aqui.

## Passo 5 — Criar `game/data/palavras.dart`

**Objetivo:** ter de onde tirar a palavra-resposta e contra o que validar o chute.

**Lógica:** duas listas, tudo em **MAIÚSCULAS e sem acento** (para bater com a comparação do controller):
- `palavrasGabarito` — 10 a 20 palavras de 5 letras (as respostas).
- `palavrasValidas` — lista maior de palavras aceitas como *chute* (inclua as do gabarito). É o que o controller consulta para recusar palavra inexistente.

E a **palavra do dia** (determinística, pra todo mundo jogar a mesma e o ranking ser justo):
1. Pegue a data de hoje e uma data fixa de referência.
2. Conte os dias entre elas.
3. Use `dias % tamanhoDaLista` como índice.

```dart
const palavrasGabarito = ['TERMO', 'CASAL', 'PRATO', /* ... */];
const palavrasValidas  = ['TERMO', 'CASAL', 'PRATO', 'BOLAR', /* ... */];

String palavraDoDia(List<String> pool) {
  final dias = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
  return pool[dias % pool.length];
}
```

## Passo 6 — Criar `game/logic/game_controller.dart`

**Objetivo:** guardar o estado da partida e avisar a tela quando ele muda. É um `ChangeNotifier`.

**O que ele guarda:**
- `_answer` — o gabarito (recebido no construtor).
- `_board` — a matriz 6×5 de `UiTile`, começa toda vazia.
- `_currentGuess` — string do que está sendo digitado na linha atual.
- `_status` — `playing` / `won` / `lost`.

**Como achar a "linha atual":** é a primeira linha ainda **inteira vazia** (`indexWhere` em que toda tile é `empty`).

**As ações (cada uma termina com `notifyListeners()`):**

1. **`onLetterTyped(letra)`** — se não está jogando, ou a linha já tem 5 letras, ignora. Senão, soma a letra (em maiúscula) a `_currentGuess` e redesenha a linha.
2. **`onBackspace()`** — se `_currentGuess` está vazio, ignora. Senão, tira o último caractere e redesenha.
3. **`submitGuess(isValidWord)`** — o miolo:
   - menos de 5 letras → retorna `"Palavra incompleta"`;
   - `isValidWord` diz que não existe → retorna `"Palavra não reconhecida"`;
   - senão, chama `evaluateGuess(_currentGuess, _answer)` e grava na linha atual;
   - decide o fim: acertou tudo → `won`; era a última linha → `lost`;
   - zera `_currentGuess` e retorna `null` (sem erro). A tela mostra a mensagem de erro num SnackBar.
4. **`_redrawCurrentRow()`** (privado) — repinta a linha atual conforme `_currentGuess`: cada posição vira `filled` com a letra, ou `empty` se ainda não digitou.

```dart
// esqueleto — você preenche o corpo dos métodos
import 'package:flutter/foundation.dart';            // ChangeNotifier
import 'package:tremapp/widgets/quadroJogo.dart';
import 'package:tremapp/game/models/game_status.dart';
import 'package:tremapp/game/logic/guess_evaluator.dart';

class GameController extends ChangeNotifier {
  static const int wordLength  = 5;
  static const int maxAttempts = 6;

  final String _answer;
  final List<List<UiTile>> _board = [];
  String _currentGuess = '';
  GameStatus _status = GameStatus.playing;

  GameController({required String answer}) : _answer = answer {
    // preencher _board com maxAttempts linhas de wordLength tiles vazias
  }

  List<List<UiTile>> get board  => _board;
  GameStatus         get status => _status;
  int get currentRow => _board.indexWhere(
    (row) => row.every((t) => t.state == TileState.empty),
  );

  void onLetterTyped(String letter) { /* ... */ }
  void onBackspace()                { /* ... */ }
  String? submitGuess(bool Function(String) isValidWord) { /* ... */ }
  void _redrawCurrentRow()          { /* ... */ }
}
```

## Passo 7 — Testar o controller

**Objetivo:** garantir as transições de estado sem abrir tela.

Em `test/game_controller_test.dart`, crie um controller com um gabarito conhecido e teste:
- digitar letras enche a linha; `onBackspace` apaga;
- `submitGuess` com menos de 5 letras devolve `"Palavra incompleta"`;
- palavra fora da lista devolve `"Palavra não reconhecida"`;
- chutar o gabarito → `status == won`;
- errar 6 vezes → `status == lost`.

Rode `flutter test`.

## Passo 8 — Plugar a UI em [game_screen.dart](lib/game_screen.dart)

**Objetivo:** a tela passa a refletir o controller (e nada mais).

1. No `_GameScreenState`, crie `late final GameController controller;` e no `initState` faça `controller = GameController(answer: palavraDoDia(palavrasGabarito));`.
2. No `build`, envolva tudo num `ListenableBuilder(listenable: controller, ...)` — ele redesenha sozinho a cada `notifyListeners()`.
3. Dentro: `BoardUiWidget(board: controller.board)`, o campo de input, e — se `controller.status != GameStatus.playing` — um banner de fim de jogo.
4. Input (caminho MVP): mantenha o `TextField`; `onChanged` chama `onLetterTyped`/`onBackspace` e `onSubmitted` chama `submitGuess`. Se `submitGuess` devolver uma mensagem, mostre num `SnackBar`.

```dart
@override
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: controller,
    builder: (_, __) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BoardUiWidget(board: controller.board),
        // campo de input -> controller.onLetterTyped / submitGuess
        if (controller.status != GameStatus.playing)
          Text(controller.status == GameStatus.won ? 'Você ganhou!' : 'Fim de jogo'),
      ],
    ),
  );
}
```

> O `PageView` do [home.dart](lib/home.dart) mantém a `GameScreen` viva ao trocar de aba, então o controller sobrevive sozinho. (Cuidado só se um dia trocar por `IndexedStack`.)

## Passo 9 — Criar `game/services/score_service.dart` e somar ao vencer

**Objetivo:** alimentar o `pontuacao` que o ranking já lê.

**Lógica:**
1. Pegue `FirebaseAuth.instance.currentUser`; se for `null`, não faça nada.
2. Calcule os pontos a partir do número de tentativas (acerto rápido vale mais).
3. Use `FieldValue.increment` no doc do usuário em `usuarios/{uid}`.
4. Chame `registrarVitoria` no controller (ou na tela) no instante em que `status` vira `won`.

```dart
Future<void> registrarVitoria({required int tentativas}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final pontos = (7 - tentativas) * 10;   // 60 na 1ª tentativa ... 10 na 6ª
  await FirebaseFirestore.instance
      .collection('usuarios').doc(user.uid)
      .update({'pontuacao': FieldValue.increment(pontos)});
}
```

> O doc já nasce com `pontuacao: 0` em [registro.dart:22](lib/registro.dart#L22) — aqui só incrementa. Envolva em `try/catch` para tolerar falha de rede.

## Passo 10 — Polimento (opcional)

- Botão "jogar de novo" (recria o controller com outra palavra).
- Teclado virtual com letras coloridas conforme já descobertas.
- Animação de flip nas tiles (`AnimatedRotation`/`AnimatedSwitcher`).
- Persistir a partida do dia com `shared_preferences` (não dá pra trapacear recarregando).

---

# Referência

## Decisões de design

| Tema | Recomendação | Por quê |
|---|---|---|
| Estado | `ChangeNotifier` nativo | Sem dependência extra, fácil de testar |
| Maiúsculas | Forçar `toUpperCase()` no controller | Evita comparar `"casa"` com `"CASA"` |
| Acentos | Palavras sem acento dos dois lados | TERMO BR não usa acento na UI |
| Validação de chute | Lista "válidas" ⊇ lista "gabarito" | Aceita mais palavras como tentativa que como resposta |
| Palavra do dia | Determinística por data | Ranking justo |
| Pontuação | `(7 - tentativas) * 10` | Recompensa acerto rápido sem zerar quem demora |

## Armadilhas (revise antes de fechar cada PR)

- **Letras repetidas** — o bug nº 1 de clones de Wordle. Teste sempre `BOLAR`/`BOBOS`.
- **Acentos** — defina "tudo sem acento" e aplique nos dois lados.
- **`const UiTile`** — só compila com construtor `const`.
- **Global `inputGuess`** — mate-a logo; quebra hot-reload e testes.
- **Firestore offline** — `score_service` deve tolerar falha de rede com `try/catch`.
