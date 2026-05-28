import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

// Navbar circular reutilizável usada pelo shell do jogo para navegar entre abas.
class GameNavBar extends StatelessWidget {
  // Índice atual destacado na navbar.
  final int activeIndex;
  // Callback disparado ao tocar em um ícone da navbar.
  final Function(int) onTap;

  const GameNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Os três ícones representam ranking, jogo e saída/login, nessa ordem.
    return CircleNavBar(
      activeIcons: const [
        Icon(Icons.leaderboard, color: Color.fromRGBO(253, 128, 46, 1.0)),
        Icon(Icons.play_arrow_rounded, color: Color.fromRGBO(253, 128, 46, 1.0)),
        Icon(Icons.logout, color: Color.fromRGBO(253, 128, 46, 1.0)),
      ],
      inactiveIcons: const [
        Icon(Icons.leaderboard, color: Color.fromRGBO(253, 128, 46, 1.0)),
        Icon(Icons.play_arrow_rounded, color: Color.fromRGBO(253, 128, 46, 1.0)),
        Icon(Icons.logout, color: Color.fromRGBO(253, 128, 46, 1.0)),
      ],
      color: Color.fromRGBO(64, 61, 57, 1),
      circleColor: Color.fromRGBO(64, 61, 57, 1),
      height: 60,
      circleWidth: 60,
      activeIndex: activeIndex,
      onTap: onTap,
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 12 + bottomInset),
      cornerRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
      shadowColor: Color.fromRGBO(253, 128, 46, 1.0),
      circleShadowColor: Color.fromRGBO(253, 128, 46, 1.0),
      elevation: 2,
    );
  }
}
