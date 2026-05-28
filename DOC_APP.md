# M.E.T.R.O. — Documentação Completa do App

Documento de referência do projeto **M.E.T.R.O.**, um clone do jogo **TERMO** (estilo Wordle
em português) feito em **Flutter + Firebase**. Objetivo: explicar o app por inteiro —
arquitetura, lógica, conceitos de base e o papel de cada tela — para qualquer pessoa da
equipe conseguir entender e evoluir o código.

> Documentos relacionados:
> - [PLANO_JOGO.md](PLANO_JOGO.md) — o plano passo a passo de como a lógica do jogo foi construída, com o estado de implementação e os desvios.
> - Comentários densos no próprio código (`lib/`), especialmente nos arquivos mais difíceis.

---

## 1. Visão geral

O jogador tem **6 tentativas** para adivinhar uma palavra de **5 letras**. A cada chute, cada
letra é pintada:

- 🟩 **verde** (`correct`) — letra certa na posição certa;
- 🟨 **amarelo** (`present`) — letra existe na palavra, mas em outra posição;
- ⬛ **cinza** (`absent`) — letra não existe na palavra.

Ao **vencer**, o jogador soma pontos em um **ranking** compartilhado (quanto menos tentativas,
mais pontos). Há login/registro de usuários e a pontuação fica salva na nuvem (Firebase).

**Stack:**
- **Flutter** (Dart) para toda a interface e lógica do cliente.
- **Firebase Authentication** para login/registro por e-mail e senha.
- **Cloud Firestore** (banco NoSQL) para guardar usuários e pontuações.
- **Gerência de estado:** `ChangeNotifier` nativo (sem Bloc/Provider/Riverpod).

---

## 2. Conceitos de base (para quem está começando)

Se você já manja de Flutter, pule para a [seção 3](#3-arquitetura-geral).

- **Widget**: tudo na tela é um widget (texto, botão, layout). A UI é uma **árvore** de widgets.
- **StatelessWidget**: widget sem estado interno — desenha a partir do que recebe e pronto
  (ex.: [BoardUiWidget](lib/widgets/quadroJogo.dart), [Ranking](lib/ranking.dart)).
- **StatefulWidget**: widget que guarda estado que muda ao longo do tempo, num objeto `State`
  separado (ex.: [GameScreen](lib/game_screen.dart), as tiles animadas). Quando o estado muda,
  chamamos `setState` (ou um mecanismo equivalente) e o Flutter redesenha.
- **`ChangeNotifier`**: uma classe que mantém dados e, quando eles mudam, chama
  `notifyListeners()` para avisar quem estiver "escutando". É a peça central da nossa lógica de
  jogo ([GameController](lib/game/logic/game_controller.dart)).
- **`ListenableBuilder`**: widget que escuta um `ChangeNotifier` e **reconstrói sozinho** a
  cada `notifyListeners()`. É a ponte entre a lógica (controller) e a tela.
- **Função pura**: função que só depende dos parâmetros e não tem efeito colateral — fácil de
  testar. Nosso [evaluateGuess](lib/game/logic/guess_evaluator.dart) é assim.
- **Future / async / await**: como o Dart lida com operações que demoram (rede, banco). As
  chamadas ao Firebase são `Future`s que aguardamos com `await`.

---

## 3. Arquitetura geral

A regra de ouro do projeto é **separar a lógica do jogo da interface**. Isso permite testar as
regras com `flutter test`, sem abrir tela.

### Camadas

```
┌─────────────────────────────────────────────────────────────┐
│ UI (Widgets)                                                 │
│  login.dart · registro.dart · home.dart · game_screen.dart   │
│  ranking.dart · widgets/ (quadroJogo, navbar)                │
│        │  lê estado / dispara ações                          │
│        ▼                                                     │
├─────────────────────────────────────────────────────────────┤
│ Lógica do jogo (game/) — PURA, sem Flutter material          │
│  logic/game_controller.dart   (estado da partida)            │
│  logic/guess_evaluator.dart   (coloração das letras)         │
│  models/game_status.dart      (enum de fase)                 │
│  data/palavras.dart           (palavras + sorteio)           │
│        │  fala com serviços                                  │
│        ▼                                                     │
├─────────────────────────────────────────────────────────────┤
│ Serviços / dados externos                                    │
│  services/score_service.dart  → Firebase Auth + Firestore    │
└─────────────────────────────────────────────────────────────┘
```

> **Regra:** arquivos em `game/logic`, `game/models` e `game/data` **nunca** importam
> `package:flutter/material.dart`. Se a lógica precisasse de `BuildContext` ou `setState`, algo
> estaria no lugar errado. (Exceção: o controller importa `flutter/foundation.dart` só por causa
> do `ChangeNotifier`, que não é UI.)

### Fluxo de dados (do toque à cor na tela)

```
usuário digita no TextField
   → GameScreen._aoDigitar traduz o texto em onLetterTyped/onBackspace
      → GameController atualiza _currentGuess e o board, chama notifyListeners()
         → ListenableBuilder redesenha o BoardUiWidget

usuário envia (Enter)
   → GameScreen._enviar chama controller.submitGuess(isValidWord)
      → submitGuess chama evaluateGuess(chute, gabarito) → 5 tiles coloridas
      → grava na linha, decide won/lost, notifyListeners()
         → BoardUiWidget redesenha; as tiles que viraram coloridas ANIMAM o flip
         → se venceu: GameScreen chama registrarVitoria() → Firestore
```

---

## 4. Inicialização e navegação

### `main.dart` — ponto de entrada
[lib/main.dart](lib/main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();      // prepara o Flutter antes de usar plugins
  await Firebase.initializeApp(options: ...);      // conecta ao projeto Firebase
  runApp(const App());                             // sobe a árvore de widgets
}
```
As credenciais do Firebase (`firebaseConfig`) ficam aqui. `main` é `async` porque precisa
esperar o Firebase inicializar **antes** de rodar o app.

### `app.dart` — `MaterialApp` e rotas
[lib/app.dart](lib/app.dart)

Define as **rotas nomeadas** do app e a rota inicial (`/login`):

| Rota | Tela | Observação |
|---|---|---|
| `/login` | `LoginPage` | rota inicial |
| `/registro` | `RegistroPage` | criar conta |
| `/home` | `Home` | shell com navbar (jogo + ranking) |
| `/ranking` | `Ranking` | ranking direto (também acessível pela aba) |
| `/game` | *(removida no Passo 1)* | era um bug — abria o jogo sem navbar |

Navegação é feita com `Navigator.of(context).pushReplacementNamed('/home')` etc.

---

## 5. As telas, uma por uma

### 5.1 Login — [login.dart](lib/login.dart)

- **O que faz:** campos de e-mail e senha + botão "Entrar". Tem link para a tela de registro.
- **Lógica:** `logar()` chama `FirebaseAuth.instance.signInWithEmailAndPassword(...)`. Se der
  certo, navega para `/home`; se falhar, mostra o erro num `SnackBar`.
- **Conceito:** a autenticação é **stateless do nosso lado** — o Firebase guarda a sessão. Depois
  do login, `FirebaseAuth.instance.currentUser` passa a existir em qualquer parte do app (é assim
  que o `score_service` sabe quem está jogando).

### 5.2 Registro — [registro.dart](lib/registro.dart)

- **O que faz:** username, e-mail e senha + botão "Registrar".
- **Lógica:** `registrar()` faz duas coisas:
  1. `createUserWithEmailAndPassword(...)` cria a conta no **Auth**;
  2. cria o **documento do usuário** no Firestore em `usuarios/{uid}` com
     `{ nome, email, pontuacao: 0 }`.
  Depois atualiza o `displayName` e navega para `/home`.
- **Detalhe importante:** o doc nasce com `pontuacao: 0`. O `score_service` depois só
  **incrementa** esse campo. (Mesmo que o doc não existisse, o `set(merge:true)` do serviço o
  criaria — ver [seção 7](#7-firebase-e-modelo-de-dados).)

### 5.3 Home (shell) — [home.dart](lib/home.dart)

É o "esqueleto" que segura as abas depois de logar. Componentes:

- **AppBar** fixa com o título "M.E.T.R.O.".
- **`PageView`** com duas páginas: `Ranking` (índice 0) e `GameScreen` (índice 1). Abre na aba
  do jogo (`activeIndex = 1`).
- **`GameNavBar`** (navbar circular) na base, com 3 ícones:
  - 🏆 ranking (aba 0),
  - ▶️ jogo (aba 1),
  - 🚪 logout → navega para `/login` (não é uma aba; sai do shell).

O `PageController` mantém `PageView` e navbar sincronizados (tanto por toque quanto por swipe).

> ⚠️ **Sutileza (keep-alive):** trocar de aba no `PageView` **descartaria** o `State` da
> `GameScreen` por padrão, recomeçando a partida. Por isso a `GameScreen` usa
> `AutomaticKeepAliveClientMixin` (ver 5.4). Já sair pelo botão de logout recria a `Home` inteira
> — aí a partida zera mesmo, e isso é esperado (é uma nova sessão).

### 5.4 GameScreen (o jogo) — [game_screen.dart](lib/game_screen.dart)

A tela mais densa. Responsabilidades:

- **Dona do `GameController`**: cria no `initState` com a **palavra do dia**
  (`palavraDoDia(palavrasGabarito)`).
- **`AutomaticKeepAliveClientMixin`**: `wantKeepAlive => true` + `super.build(context)` mantêm a
  partida viva ao trocar de aba.
- **Entrada de texto (`_aoDigitar`)**: o `TextField` avisa pela string inteira (`onChanged`), mas
  o controller pensa em eventos (`onLetterTyped`/`onBackspace`). `_aoDigitar` **reconcilia**
  comparando o tamanho do texto novo com o `currentGuess`: cresceu → digitou letras; encolheu →
  apagou. O controller é a fonte única da verdade; o board é desenhado a partir dele, nunca do
  campo.
- **Enviar (`_enviar`)**: chama `submitGuess`, passando a validação
  `palavrasValidas.contains(palavra)`. Se voltar mensagem de erro, mostra `SnackBar`. Se venceu
  (e ainda não pontuou), calcula as tentativas e chama `registrarVitoria`.
  - **Cálculo de tentativas:** após o submit vitorioso, `currentRow` aponta para a próxima linha
    vazia, cujo índice = número de linhas usadas. Se acertou na última linha, `currentRow == -1`
    e usamos `maxAttempts`.
- **`_jogarDeNovo`**: reseta a trava de pontuação, limpa o campo e chama
  `controller.reiniciar(answer: palavraAleatoria(...))` — **palavra nova aleatória**.
- **`build`**: tudo dentro de um `ListenableBuilder` que escuta o controller. Mostra o
  `BoardUiWidget`, o `TextField` (travado quando o jogo acaba) e, no fim de jogo, o banner
  ("Você ganhou!" / "Fim de jogo! A palavra era X") + botão "Jogar de novo".

### 5.5 Ranking — [ranking.dart](lib/ranking.dart)

- **O que faz:** lista os usuários ordenados por `pontuacao` (maior primeiro), com posição
  (#1, #2…), nome e pontos.
- **Lógica:** usa um **`StreamBuilder`** sobre
  `FirebaseFirestore.instance.collection('usuarios').orderBy('pontuacao', descending: true).snapshots()`.
  Como é um **stream**, o ranking **atualiza em tempo real** — assim que alguém pontua, a lista se
  reordena sozinha, sem recarregar.
- **Extra:** botão ⓘ ("como pontuar") ao lado do título abre um diálogo explicando a fórmula de
  pontos.

---

## 6. A camada de lógica do jogo (`game/`)

### 6.1 `models/game_status.dart`
[lib/game/models/game_status.dart](lib/game/models/game_status.dart)

```dart
enum GameStatus { playing, won, lost }
```
As três fases da partida. Simples, mas central: a tela decide o que mostrar com base nisso.

### 6.2 `data/palavras.dart`
[lib/game/data/palavras.dart](lib/game/data/palavras.dart)

Três coisas, tudo **MAIÚSCULO e sem acento** (para a comparação bater):

- `palavrasGabarito` — as palavras que podem ser sorteadas como resposta (5 letras cada).
- `palavrasValidas` — **superconjunto** do gabarito; o que aceitamos como **chute**. Inclui as do
  gabarito + extras. É o que recusa "palavra não reconhecida".
- `palavraDoDia(pool)` — **determinística por data**: conta os dias desde `2026-01-01` e usa
  `dias % pool.length` como índice. Todo mundo joga a mesma palavra no mesmo dia → ranking justo.
- `palavraAleatoria(pool)` — sorteia qualquer palavra (usada no "jogar de novo").

### 6.3 `logic/guess_evaluator.dart` — o coração
[lib/game/logic/guess_evaluator.dart](lib/game/logic/guess_evaluator.dart)

Função **pura** `evaluateGuess(guess, answer)` que devolve as 5 tiles já coloridas.

**Por que é o ponto mais delicado:** letras repetidas. A conta ingênua erra. Solução: tratar o
gabarito como um **estoque** e ir **consumindo** as letras. Em **dois passos**:

1. **Verdes primeiro:** para cada posição, se `chute[i] == gabarito[i]`, marca `correct` e
   **remove** essa letra do estoque. Faz isso na linha toda antes do passo 2 (prioridade aos verdes).
2. **Amarelos e cinzas:** para cada posição restante, procura a letra no **estoque que sobrou**.
   Achou → `present` (amarelo) e **consome**; não achou → `absent` (cinza).

> **Teste canônico:** gabarito `BOLAR`, chute `BOBOS`. O 2º `B` deve ser **cinza** (não amarelo),
> porque o único `B` do gabarito já foi "gasto" pelo verde. Se isso quebra, o algoritmo está errado.

### 6.4 `logic/game_controller.dart` — o estado da partida
[lib/game/logic/game_controller.dart](lib/game/logic/game_controller.dart)

Um `ChangeNotifier`. Guarda:
- `_answer` (gabarito), `_board` (matriz 6×5 de tiles), `_currentGuess` (linha em digitação),
  `_status`.

Expõe getters de leitura (`board`, `status`, `answer`, `currentGuess`) e:

- **`currentRow`** — a "linha atual". **Atenção ao bug clássico:** NÃO é "primeira linha toda
  vazia". Enquanto digita, as tiles viram `filled`; se exigíssemos `empty`, o índice pularia de
  linha. A definição correta é "primeira linha sem nenhuma tile **colorida**" (aceita `empty` ou
  `filled`). Linhas já enviadas têm cor e por isso não contam.
- **`onLetterTyped` / `onBackspace`** — editam `_currentGuess` e repintam a linha; cada uma
  termina com `notifyListeners()`.
- **`submitGuess(isValidWord)`** — o miolo: valida tamanho e existência da palavra (retorna
  mensagem de erro ou `null`), chama `evaluateGuess`, grava na linha, decide `won`/`lost`, zera o
  chute e notifica.
- **`reiniciar({answer})`** — zera board/chute/status e troca o gabarito (usado no "jogar de novo").
- **`_redrawCurrentRow()`** (privado) — repinta a linha atual conforme `_currentGuess`.

### 6.5 `services/score_service.dart` — pontuação
[lib/game/services/score_service.dart](lib/game/services/score_service.dart)

`registrarVitoria({tentativas})`:
1. Pega `FirebaseAuth.instance.currentUser`; se `null`, não faz nada.
2. Calcula `pontos = (7 - tentativas) * 10` (60 na 1ª tentativa … 10 na 6ª).
3. Soma no Firestore com `set({'pontuacao': FieldValue.increment(pontos)}, SetOptions(merge: true))`.

> **Por que `set(merge)` e não `update`:** `update` **falha se o doc não existir**, e o `try/catch`
> esconderia o erro — pontos sumiam silenciosamente. `set(merge:true)` soma existindo o doc ou não.
> O `catch` ainda existe para tolerar offline, mas agora dá `debugPrint` para facilitar diagnóstico.

---

## 7. Firebase e modelo de dados

### Authentication
Login/registro por **e-mail e senha**. A sessão é gerenciada pelo Firebase; consultamos
`FirebaseAuth.instance.currentUser` quando precisamos do `uid`.

### Cloud Firestore
Uma coleção: **`usuarios`**. Cada documento tem o **id = uid** do usuário no Auth, e os campos:

| Campo | Tipo | Origem |
|---|---|---|
| `nome` | string | preenchido no registro |
| `email` | string | preenchido no registro |
| `pontuacao` | number | nasce `0` no registro, cresce via `FieldValue.increment` ao vencer |

O ranking lê essa coleção ordenada por `pontuacao desc`, **em tempo real** (stream).

> **Pontuação determinística e justa:** como a palavra do dia é a mesma para todos, a disputa do
> ranking faz sentido. (O "jogar de novo" usa palavra aleatória e também soma pontos — decisão de
> design registrada no [PLANO_JOGO.md](PLANO_JOGO.md#desvios-do-plano-importantes).)

---

## 8. A animação de flip (deep dive)

Implementada em `_TileWidget` dentro de [quadroJogo.dart](lib/widgets/quadroJogo.dart). É a parte
mais "matemática" do código; vale entender bem.

**Ideia:** quando o jogador envia o chute, a tile **gira** sobre o eixo vertical (como virar uma
carta) e revela a cor do resultado. As 5 tiles da linha viram **em cascata** (uma após a outra).

**Como funciona, em pontos:**

- **`_TileWidget` é Stateful** porque precisa de um `AnimationController` (tem ciclo de vida).
- **O disparo vem de `didUpdateWidget`:** comparamos o estado **antigo** com o **novo** da tile.
  Se foi de "não-revelado" (`empty`/`filled`) para "revelado" (`correct`/`present`/`absent`),
  animamos. Como só a linha recém-enviada vira colorida, o disparo acerta exatamente as tiles
  certas — digitar letras nunca dispara.
- **Cascata (stagger):** cada tile atrasa o início por `coluna × 250ms` (`Future.delayed`), então
  elas viram da esquerda para a direita.
- **A matemática do giro (no `build`):**
  - O progresso `t` vai de 0 a 1.
  - O ângulo é `(t < 0.5 ? t : 1 - t) * pi` — **sobe** até 90° (a tile fica de perfil, some) e
    **desce** de volta a 0°. É um "vai e volta".
  - A **cor troca no meio** (`t >= 0.5`): na primeira metade mostra a letra digitada (sem cor); na
    segunda, a cor do resultado. Como a troca acontece quando a tile está de perfil (invisível), o
    olho não percebe o "corte" — parece que a carta virou.
  - `Matrix4..setEntry(3, 2, 0.001)` adiciona **perspectiva** (profundidade) ao giro 3D;
    `..rotateY(angle)` gira no eixo vertical (flip **horizontal**).
- **Interação com keep-alive:** ao voltar para a aba do jogo, o `State` é preservado e o controller
  da tile fica em `value = 1` (já revelada) → `didUpdateWidget` vê "revelado → revelado" e **não
  re-anima**. Ao reiniciar a partida (tiles voltam a `empty`), o controller volta a `0` para a
  próxima revelação animar de novo.

**Ajuste rápido de ritmo:** as constantes `_kFlipDuration` (duração de cada flip) e `_kFlipStagger`
(atraso entre tiles) ficam no topo de `_TileWidget` em [quadroJogo.dart](lib/widgets/quadroJogo.dart).

---

## 9. Testes

Pasta [test/](test/), rodados com `flutter test`:

- **[guess_evaluator_test.dart](test/guess_evaluator_test.dart)** — prova a coloração: acerto
  total, tudo errado, letra repetida no chute, letra repetida no gabarito, e a mistura
  verde/amarelo/cinza. É o teste mais importante (cobre o bug de letras repetidas).
- **[game_controller_test.dart](test/game_controller_test.dart)** — transições de estado:
  digitar/apagar, palavra incompleta, palavra não reconhecida, vitória e derrota (6 erros).

A lógica ser **pura e separada da UI** é o que permite testar tudo isso sem abrir tela. Serviços
que dependem do Firebase (`score_service`) não são testados aqui — exigiriam mocks/emulador.

---

## 10. Como rodar

```bash
flutter pub get      # baixa dependências
flutter analyze      # checa erros/avisos estáticos
flutter test         # roda os testes da lógica
flutter run          # sobe o app num emulador/dispositivo
```

Dependências principais (ver [pubspec.yaml](pubspec.yaml)): `firebase_core`, `firebase_auth`,
`cloud_firestore`, `circle_nav_bar`.

---

## 11. Glossário rápido

| Termo | Significado no projeto |
|---|---|
| **tile** | Cada célula do tabuleiro (uma letra). Modelada por `UiTile` + `TileState`. |
| **board** | A matriz 6×5 de tiles (6 tentativas × 5 letras). |
| **gabarito / answer** | A palavra secreta que o jogador tenta adivinhar. |
| **chute / guess** | A palavra que o jogador digita numa tentativa. |
| **palavra do dia** | Palavra determinística pela data — a mesma para todos no mesmo dia. |
| **controller** | O `GameController`, dono do estado da partida. |
| **evaluator** | `evaluateGuess`, função pura que decide as cores. |
| **reveal / flip** | A animação de virar a tile para mostrar a cor após o submit. |
