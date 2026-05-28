// game/services/score_service.dart — soma pontos no Firestore quando o jogador vence,
// com RESET DIÁRIO automático: cada documento guarda a data da pontuação atual
// (`dataPontuacao` em YYYY-MM-DD) e o ranking filtra só quem pontuou hoje.
//
// LÓGICA do reset (sem precisar de cron / Cloud Functions):
//   - Se o usuário JÁ pontuou hoje (campo `dataPontuacao` == hoje):
//       incrementa `pontuacao` normalmente — somam as vitórias do dia.
//   - Se NÃO pontuou hoje (data diferente ou doc novo sem o campo):
//       grava `pontuacao = pontos` e `dataPontuacao = hoje` — efetivamente "zera"
//       a pontuação do dia anterior e começa o placar de hoje. Como a tela de
//       ranking filtra por `dataPontuacao == hoje`, docs com data antiga simplesmente
//       somem da lista — o "reset" acontece de graça, sem precisar apagar nada.
//
// Tudo isso é feito dentro de uma TRANSAÇÃO Firestore para evitar que duas vitórias
// quase simultâneas (ex.: dois dispositivos do mesmo usuário) leiam um estado velho
// e cada uma sobrescreva a outra — a transação garante leitura+escrita atômicas.

import 'package:flutter/foundation.dart'; // debugPrint (log que só aparece em debug)
import 'package:firebase_auth/firebase_auth.dart'; // saber quem é o usuário logado
import 'package:cloud_firestore/cloud_firestore.dart'; // gravar no banco
import 'package:tremapp/game/data/datas.dart'; // hojeISO() — chave do "dia atual"

// Registra a vitória do usuário atual somando pontos ao seu documento.
// Recebe em quantas tentativas ele acertou (quanto mais rápido, mais pontos).
Future<void> registrarVitoria({required int tentativas}) async {
  final user = FirebaseAuth.instance.currentUser; // pega o usuário logado
  if (user == null) return; // sem usuário logado, não há onde somar pontos

  final pontos = (7 - tentativas) * 10; // 1ª tentativa = 60 pts ... 6ª = 10 pts
  final hoje = hojeISO(); // chave de "dia atual" (ex.: "2026-05-27")
  // Referência ao doc deste usuário (id do doc == uid do Auth, criado no registro).
  final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

  try {
    // runTransaction: o callback pode rodar mais de uma vez se houver conflito,
    // por isso ele PRECISA ser puro (sem efeitos externos). Aqui ele só lê o doc
    // e escolhe entre incrementar (mesmo dia) ou resetar (dia novo).
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref); // estado atual do doc dentro da transação
      // "Mesmo dia" só vale se o doc existe E a dataPontuacao bate com hoje.
      // Doc novo ou dia diferente cai no else (reset).
      final mesmoDia =
          snap.exists && snap.data()?['dataPontuacao'] == hoje;

      if (mesmoDia) {
        // Já pontuou hoje: soma os pontos desta vitória aos pontos do dia.
        // FieldValue.increment é uma operação atômica do Firestore — não exige ler antes.
        tx.update(ref, {'pontuacao': FieldValue.increment(pontos)});
      } else {
        // Primeiro registro do dia (ou doc novo): SUBSTITUI a pontuação anterior
        // pela pontuação desta vitória e marca a data de hoje. merge:true preserva
        // outros campos do doc (nome, email) e cria os que faltam.
        tx.set(
          ref,
          {'pontuacao': pontos, 'dataPontuacao': hoje},
          SetOptions(merge: true),
        );
      }
    });
  } catch (e) {
    // Tolera falha de rede / offline: o jogo continua mesmo se o placar não subir agora.
    debugPrint('Falha ao registrar vitória: $e'); // ao menos loga para facilitar diagnóstico
  }
}
