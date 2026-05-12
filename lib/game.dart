import 'package:flutter/material.dart';
import 'widgets/navbar.dart';
import 'ranking.dart';
import 'game_screen.dart';

// Tela shell do jogo: mantém a AppBar e a navbar fixas enquanto troca apenas o conteúdo central.
class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game>
  with SingleTickerProviderStateMixin {
  // Índice da aba atualmente selecionada na navbar e no PageView.
  int activeIndex = 1;

  int get tabIndex => activeIndex;
  set tabIndex(int v) {
    activeIndex = v;
    setState(() {});
  }
  
  // Controla a troca programática de páginas quando o usuário toca nos ícones da navbar.
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: activeIndex);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(Colors.transparent.value),
        title: Text("M.E.T.R.O.", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color.fromRGBO(253, 128, 46, 1.0))),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Navigator.of(context).pushReplacementNamed('/login');
        //     },
        //     icon: Icon(Icons.logout),
        //   )
        // ],
      ),
      backgroundColor: const Color.fromRGBO(64, 61, 57, 1),
      // O corpo muda conforme a aba escolhida; a estrutura externa permanece igual.
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            tabIndex = index;
          });
        },
        children: const [
          Ranking(),
          GameScreen(),
        ],
      ),
      // Navbar reutilizável: a aba 2 é reservada para sair e voltar para /login.
      bottomNavigationBar: GameNavBar(
        activeIndex: tabIndex,
        onTap: (v) {
          if (v == 2) {
            Navigator.of(context).pushReplacementNamed('/login');
            return;
          }

          setState(() {
            tabIndex = v;
          });
          pageController.jumpToPage(v);
        },
      ),
    );
  }
}