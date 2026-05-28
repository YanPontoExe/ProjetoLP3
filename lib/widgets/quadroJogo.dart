/*lib/widgets/board_ui_widget.dart

BoardUiWidget - renderiza o grid 6×5 do jogo (UI only, sem lógica de jogo).

É um StatelessWidget porque ele não tem estado próprio:
recebe o board pronto e só exibe.*/

import 'dart:math'; // pi, para calcular o ângulo do flip
import 'package:flutter/material.dart';

// Estados das tiles

enum TileState {
  empty,   // célula vazia
  filled,  // letra sendo digitada
  correct, // letra correta (verde)
  present, // letra presente em outro lugar (amarelo)
  absent,  // letra não existe na palavra (cinza)
}

// Estrutura de dados de uma tile

class UiTile {
  final String letter;
  final TileState state;

  UiTile({
    required this.letter,
    this.state = TileState.empty,
  });
}

// BoardUiWidget - widget principal do board

class BoardUiWidget extends StatelessWidget {
  final List<List<UiTile>> board;

  const BoardUiWidget({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 420 ? 12.0 : 32.0;
        final tileSize = ((constraints.maxWidth - (horizontalPadding * 2) - 16) / 5)
            .clamp(34.0, 59.0)
            .toDouble();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              board.length,
              (row) => Padding(
                padding: EdgeInsets.only(bottom: row == board.length - 1 ? 0 : 10),
                child: _RowWidget(tiles: board[row], tileSize: tileSize),
              ),
            ),
          ),
        );
      },
      );
  }
}

// _RowWidget - uma linha do board (5 tiles)

class _RowWidget extends StatelessWidget {
  final List<UiTile> tiles;
  final double tileSize;

  const _RowWidget({required this.tiles, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int index = 0; index < tiles.length; index++) ...[
          _TileWidget(tile: tiles[index], tileSize: tileSize, index: index),
          if (index != tiles.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

// =============================================================================
// _TileWidget — célula individual com animação de "flip" no reveal pós-submit.
// -----------------------------------------------------------------------------
// IDEIA GERAL (estilo TERMO/Wordle):
//   Enquanto o jogador digita, a tile só mostra a letra (estado `filled`), SEM cor.
//   Quando ele envia o chute, o controller troca o estado da tile para a cor do
//   resultado (correct/present/absent). É ESSA TROCA que dispara o flip: a tile
//   "gira" sobre o eixo vertical, e a cor só aparece quando ela passa do meio do
//   giro — dando a sensação de que está virando uma carta para revelar o resultado.
//
// POR QUE É UM StatefulWidget:
//   A animação precisa de um AnimationController, que tem ciclo de vida (criar no
//   initState, descartar no dispose). Um StatelessWidget não guardaria esse estado.
//
// COMO O FLIP É DISPARADO SEM "GAMBIARRA":
//   Não precisamos avisar a tile "agora anime". Em `didUpdateWidget` comparamos o
//   estado ANTIGO com o NOVO: se saiu de não-revelado → revelado, animamos. Como só
//   a linha recém-enviada muda para colorida, o disparo acerta exatamente as tiles
//   certas — digitar letras (filled↔empty) nunca cai nessa condição, então não anima.
//
// INTERAÇÃO COM O keep-alive da GameScreen:
//   A GameScreen usa AutomaticKeepAliveClientMixin, então ao trocar de aba o State
//   das tiles é preservado. Quando o board é reconstruído, o Flutter reaproveita o
//   mesmo _TileWidgetState (mesmo tipo, mesma posição) e o controller fica em value=1
//   (já revelada) → didUpdateWidget vê "revelado → revelado" e NÃO re-anima. Bom.
// =============================================================================

// Tempo de cada flip e o atraso somado por coluna (faz a revelação cascatear:
// a tile 0 começa em 0ms, a 1 em 250ms, a 2 em 500ms... uma após a outra).
const Duration _kFlipDuration = Duration(milliseconds: 250);
const Duration _kFlipStagger  = Duration(milliseconds: 250);

class _TileWidget extends StatefulWidget {
  final UiTile tile;
  final double tileSize;
  final int index; // posição da tile na linha (0..4), usada para escalonar o flip

  const _TileWidget({required this.tile, required this.tileSize, required this.index});

  @override
  State<_TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<_TileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller; // controla o progresso do flip (0 a 1)

  // Uma tile está "revelada" quando já tem cor de resultado (verde/amarelo/cinza).
  bool _isRevealed(TileState s) =>
      s == TileState.correct || s == TileState.present || s == TileState.absent;

  @override
  void initState() {
    super.initState();
    // O controller mede o progresso da animação de 0.0 a 1.0 ao longo de _kFlipDuration.
    // `vsync: this` o sincroniza com o refresh da tela (por isso o SingleTickerProviderStateMixin).
    _controller = AnimationController(vsync: this, duration: _kFlipDuration);
    // Caso de borda: se a tile JÁ nasce revelada, não queremos vê-la animar do nada.
    // Isso acontece quando o State é recriado com o board já preenchido — ex.: o
    // jogador volta para a aba do jogo. Pular direto para value=1 a mostra colorida e parada.
    if (_isRevealed(widget.tile.state)) _controller.value = 1;
  }

  // didUpdateWidget roda toda vez que o BoardUiWidget é reconstruído e entrega uma
  // nova instância de _TileWidget para ESTE mesmo State (mesma posição na grade).
  // `old` é a tile anterior; `widget.tile` é a nova. Comparar os dois é como
  // detectamos a transição que merece animação, sem precisar de flag externa.
  @override
  void didUpdateWidget(_TileWidget old) {
    super.didUpdateWidget(old);
    if (!_isRevealed(old.tile.state) && _isRevealed(widget.tile.state)) {
      // TRANSIÇÃO "enviou o chute": era filled/empty e virou colorida.
      // Atrasamos o início por (coluna × stagger) para as tiles da linha virarem em
      // sequência da esquerda para a direita, em cascata, e não todas de uma vez.
      // O `if (mounted)` protege contra o widget ter saído da árvore durante o atraso
      // (ex.: trocou de tela), o que faria forward() lançar erro num controller morto.
      Future.delayed(_kFlipStagger * widget.index, () {
        if (mounted) _controller.forward(from: 0);
      });
    } else if (_isRevealed(old.tile.state) && !_isRevealed(widget.tile.state)) {
      // TRANSIÇÃO "novo jogo": era colorida e voltou a ser vazia (reiniciar()).
      // Voltamos o controller a 0 para que a PRÓXIMA revelação volte a animar do início.
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Cor de fundo conforme o estado passado (não necessariamente o final, por causa do flip).
  Color _backgroundColor(TileState state) {
    return switch (state) {
      TileState.correct => const Color(0xFF538D4E), // verde
      TileState.present => const Color(0xFFB59F3B), // amarelo
      TileState.absent  => const Color(0xFF3A3A3C), // cinza
      _                 => Colors.transparent,       // vazio ou filled
    };
  }

  // Cor da borda conforme o estado.
  Color _borderColor(TileState state) {
    return switch (state) {
      TileState.correct => const Color(0xFF538D4E),
      TileState.present => const Color(0xFFB59F3B),
      TileState.absent  => const Color(0xFF3A3A3C),
      TileState.filled  => const Color(0xFF565758), // borda clara quando digitando
      TileState.empty   => const Color.fromARGB(188, 253, 129, 46), // borda escura quando vazio
    };
  }

  // Desenha a caixa da tile para um dado estado (a letra é sempre a mesma).
  Widget _box(TileState state) {
    return Container(
      width: widget.tileSize,
      height: widget.tileSize,
      decoration: BoxDecoration(
        color:  _backgroundColor(state),
        border: Border.all(color: _borderColor(state), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.tile.letter,
        style: const TextStyle(
          fontSize:   28,
          fontWeight: FontWeight.bold,
          color:      Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder reexecuta este builder a cada frame da animação (cada vez que
    // _controller muda de valor), redesenhando a tile com o novo ângulo de giro.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // progresso: 0 = início, 0.5 = meio, 1 = fim

        // ÂNGULO DO GIRO — a parte que mais confunde. Queremos que a tile gire até
        // ficar "de perfil" (90° = pi/2 rad, quando some da vista) e DEPOIS volte a
        // 0°, agora mostrando a face colorida. Por isso o ângulo SOBE e DESCE:
        //   t de 0.0→0.5  →  (t)     vai de 0  até pi/2   (some de vista)
        //   t de 0.5→1.0  →  (1 - t) vai de pi/2 até 0    (reaparece já colorida)
        // O `(t < 0.5 ? t : 1 - t)` cria justamente esse "vai e volta" simétrico.
        final angle = (t < 0.5 ? t : 1 - t) * pi;

        // TROCA DE FACE no meio do giro: enquanto t < 0.5 (primeira metade) ainda
        // mostramos a face "de antes" (a letra que o jogador digitou, sem cor); a
        // partir de t >= 0.5 mostramos a face final (a cor do resultado). Como a
        // troca acontece quando a tile está de perfil (invisível), o olho não vê o
        // "corte" — parece que a carta virou e revelou o outro lado.
        final estado = t >= 0.5
            ? widget.tile.state // face revelada (verde/amarelo/cinza)
            : (widget.tile.letter.isEmpty ? TileState.empty : TileState.filled); // face "antes"

        return Transform(
          alignment: Alignment.center, // gira em torno do próprio centro
          transform: Matrix4.identity()
            // setEntry(3,2, 0.001) injeta um pouco de PERSPECTIVA na matriz 4x4: sem
            // isso a rotação 3D pareceria achatada (ortográfica); com isso a tile
            // ganha leve profundidade ao virar, como um objeto real girando.
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle), // gira em torno do eixo Y (vertical) → flip horizontal
          child: _box(estado),
        );
      },
    );
  }
}
