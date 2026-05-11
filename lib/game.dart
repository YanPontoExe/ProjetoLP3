import 'package:flutter/material.dart';

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(Colors.grey[500]!.value),
        title: Text("M.E.T.R.O.", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      backgroundColor: Color(Colors.grey[500]!.value),
      body: Container(
        alignment: .center,
        child: Text("JOGO", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)
      ),
    )
  );
  }
}