import 'package:flutter/material.dart';
import 'widgets/navbar.dart';
import 'ranking.dart';
import 'game_screen.dart';

// Tela principal do app: funciona como shell e mantém a estrutura de navegação fixa.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
  with SingleTickerProviderStateMixin {
  // Índice da aba atual exibida no PageView e destacada na navbar.
  int activeIndex = 1;

  // Getter e setter usados para manter o índice sincronizado com a UI.
  int get tabIndex => activeIndex;
  set tabIndex(int v) {
    activeIndex = v;
    setState(() {});
  }
  
  // Controla a troca de páginas quando o usuário toca nos ícones da navbar.
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    // Inicia abrindo a aba do jogo por padrão.
    pageController = PageController(initialPage: activeIndex);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior fixa com o nome do app.
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(Colors.transparent.value),
        title: Text("M.E.T.R.O.", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color.fromRGBO(253, 128, 46, 1.0))),
      ),
      backgroundColor: const Color.fromRGBO(64, 61, 57, 1),
      // O conteúdo central muda conforme a aba selecionada.
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          // Atualiza a navbar quando o usuário troca de página por swipe.
          setState(() {
            tabIndex = index;
          });
        },
        // Ordem das páginas: ranking, jogo.
        children: const [
          Ranking(),
          GameScreen(),
        ],
      ),
      // Navbar circular compartilhada entre as abas; o botão 2 redireciona para login.
      bottomNavigationBar: GameNavBar(
        activeIndex: tabIndex,
        onTap: (v) {
          // O terceiro ícone não abre aba; ele leva o usuário para a tela de login.
          if (v == 2) {
            Navigator.of(context).pushReplacementNamed('/login');
            return;
          }

          // Sincroniza a navbar e o PageView com a aba escolhida.
          setState(() {
            tabIndex = v;
          });
          pageController.jumpToPage(v);
        },
      ),
    );
  }
}