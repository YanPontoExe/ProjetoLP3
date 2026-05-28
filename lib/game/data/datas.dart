// game/data/datas.dart — utilidades de data, PURO (sem Flutter).
// Usado pelo score_service (gravar a data da pontuação) e pelo ranking
// (filtrar só quem pontuou hoje), para o ranking "zerar" todo dia.

// Devolve a data de hoje no formato ISO curto YYYY-MM-DD (ex.: "2026-05-27").
// Esse formato é usado como string no Firestore para comparar igualdade ("é hoje?")
// sem precisar lidar com horas/timezones — duas vitórias no mesmo dia local
// produzem a mesma chave, e o ranking filtra docs com chave igual à de hoje.
String hojeISO() {
  final agora = DateTime.now();
  final mes = agora.month.toString().padLeft(2, '0'); // garante 2 dígitos: 5 -> "05"
  final dia = agora.day.toString().padLeft(2, '0');
  return '${agora.year}-$mes-$dia';
}
