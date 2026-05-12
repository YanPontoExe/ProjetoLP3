import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Ranking extends StatelessWidget {
  const Ranking({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(64, 61, 57, 1),

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text("RANKING", style: TextStyle(fontWeight: FontWeight.w900, color: Color.fromRGBO(253, 128, 46, 1.0), fontSize: 18),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('pontuacao', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar ranking"));
          }

          final usuarios = snapshot.data!.docs;

          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              var dados = usuarios[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: Text(
                  "#${index + 1}",
                  style: TextStyle(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                title: Text(
                  dados['nome'] ?? 'Sem nome',
                  style: TextStyle(color: Colors.white),
                ),

                trailing: Text(
                  "${dados['pontuacao']} pts",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}