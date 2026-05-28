import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'game/data/datas.dart'; // hojeISO() — chave usada para filtrar só quem pontuou hoje

class Ranking extends StatelessWidget {
  const Ranking({super.key});

  // Abre um diálogo explicando como o jogador ganha pontos.
  void _mostrarComoPontuar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(64, 61, 57, 1),
        title: const Text(
          "Como pontuar",
          style: TextStyle(
            color: Color.fromRGBO(253, 128, 46, 1.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min, // o diálogo só ocupa o necessário
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Você ganha pontos ao acertar a palavra. Quanto menos tentativas usar, mais pontos:",
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 12),
            // Tabela de pontos: (7 - tentativas) * 10
            Text("1ª tentativa  →  60 pts", style: TextStyle(color: Colors.white)),
            Text("2ª tentativa  →  50 pts", style: TextStyle(color: Colors.white)),
            Text("3ª tentativa  →  40 pts", style: TextStyle(color: Colors.white)),
            Text("4ª tentativa  →  30 pts", style: TextStyle(color: Colors.white)),
            Text("5ª tentativa  →  20 pts", style: TextStyle(color: Colors.white)),
            Text("6ª tentativa  →  10 pts", style: TextStyle(color: Colors.white)),
            SizedBox(height: 12),
            Text(
              "Se as 6 tentativas acabarem sem acerto, nenhum ponto é somado.",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              "O ranking zera todo dia: só aparecem aqui jogadores que pontuaram hoje.",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // fecha o diálogo
            child: const Text(
              "Entendi",
              style: TextStyle(color: Color.fromRGBO(253, 128, 46, 1.0)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(64, 61, 57, 1),

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min, // mantém título + botão centralizados juntos
          children: [
            Text("RANKING", style: TextStyle(fontWeight: FontWeight.w900, color: Color.fromRGBO(253, 128, 46, 1.0), fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Color.fromRGBO(253, 128, 46, 1.0)),
              tooltip: "Como funciona a pontuação",
              onPressed: () => _mostrarComoPontuar(context), // abre a explicação
            ),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        // Filtra só usuários cuja pontuação foi registrada HOJE — assim o ranking
        // "zera" todo dia automaticamente: docs com dataPontuacao de dias anteriores
        // simplesmente não aparecem (e voltam a aparecer quando o usuário vencer hoje).
        //
        // NÃO usamos .orderBy aqui de propósito: where + orderBy em campos DIFERENTES
        // exigiria criar um índice composto no console do Firebase. Como filtramos por
        // um único campo (`dataPontuacao` em igualdade), o índice single-field
        // automático do Firestore basta. A ordenação por pontuação é feita no cliente,
        // logo abaixo. Como o ranking é pequeno (só quem pontuou HOJE), ordenar em Dart
        // não pesa.
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('dataPontuacao', isEqualTo: hojeISO())
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar ranking"));
          }

          // Ordena por pontuação (maior primeiro) no cliente. `toList()` cria uma cópia
          // mutável (snapshot.data!.docs é imutável); o `..sort` faz a ordenação in-place.
          // O `?? 0` protege contra docs antigos que talvez não tenham o campo `pontuacao`.
          final usuarios = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final pa = ((a.data() as Map)['pontuacao'] ?? 0) as num;
              final pb = ((b.data() as Map)['pontuacao'] ?? 0) as num;
              return pb.compareTo(pa); // pb antes de pa → ordem decrescente
            });

          // Estado vazio: ninguém pontuou hoje ainda (ou todos os docs de hoje sumiram).
          if (usuarios.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Ninguém pontuou hoje ainda.\nSeja o primeiro!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }

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