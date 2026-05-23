// lib/widgets/board_ui_widget.dart
//
// BoardUiWidget — renderiza o grid 6×5 do jogo (UI only, sem lógica de jogo).
//
// É um StatelessWidget porque ele não tem estado próprio:
// recebe o board pronto e só exibe.

import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// Estados das tiles
// ──────────────────────────────────────────────

enum TileState {
  empty,   // célula vazia
  filled,  // letra sendo digitada
  correct, // letra correta (verde)
  present, // letra presente em outro lugar (amarelo)
  absent,  // letra não existe na palavra (cinza)
}

// ──────────────────────────────────────────────
// Estrutura de dados de uma tile
// ──────────────────────────────────────────────

class UiTile {
  final String letter;
  final TileState state;

  UiTile({
    required this.letter,
    this.state = TileState.empty,
  });
}

// ──────────────────────────────────────────────
// BoardUiWidget — widget principal do board
// ──────────────────────────────────────────────

class BoardUiWidget extends StatelessWidget {
  final List<List<UiTile>> board;

  const BoardUiWidget({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          board.length,
          (row) => _RowWidget(tiles: board[row]),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// _RowWidget — uma linha do board (5 tiles)
// ──────────────────────────────────────────────

class _RowWidget extends StatelessWidget {
  final List<UiTile> tiles;

  const _RowWidget({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: tiles.map((tile) => _TileWidget(tile: tile)).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// _TileWidget — célula individual
// ──────────────────────────────────────────────

class _TileWidget extends StatelessWidget {
  final UiTile tile;

  const _TileWidget({required this.tile});

  // Retorna a cor de fundo baseada no estado da letra
  Color _backgroundColor() {
    return switch (tile.state) {
      TileState.correct => const Color(0xFF538D4E), // verde
      TileState.present => const Color(0xFFB59F3B), // amarelo
      TileState.absent  => const Color(0xFF3A3A3C), // cinza
      _                 => Colors.transparent,       // vazio ou filled
    };
  }

  // Retorna a cor da borda
  Color _borderColor() {
    return switch (tile.state) {
      TileState.correct => const Color(0xFF538D4E),
      TileState.present => const Color(0xFFB59F3B),
      TileState.absent  => const Color(0xFF3A3A3C),
      TileState.filled  => const Color(0xFF565758), // borda clara quando digitando
      TileState.empty   => const Color.fromARGB(188, 253, 129, 46), // borda escura quando vazio
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  59,
      height: 59,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:  _backgroundColor(),
        border: Border.all(color: _borderColor(), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        tile.letter,
        style: const TextStyle(
          fontSize:   28,
          fontWeight: FontWeight.bold,
          color:      Colors.white,
        ),
      ),
    );
  }
}
