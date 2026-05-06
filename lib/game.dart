import 'package:flutter/material.dart';

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(Colors.grey[500]!.value),
      body: Container(
        alignment: .center,
        child: Column(
          children: [
            Text("M.E.T.R.O.", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            
          ],

        ),
      ),
    );
  }
}