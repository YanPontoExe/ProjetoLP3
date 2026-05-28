// game/data/palavras.dart — PURO, sem Flutter
// Fonte das palavras do jogo: de onde sai a resposta e contra o que validamos o chute.
// Tudo em MAIÚSCULAS e SEM ACENTO para bater com a comparação feita no controller.
import 'dart:math'; // Random, para sortear palavra ao "jogar de novo"

// Lista de respostas possíveis (o "gabarito" que o jogador precisa adivinhar).
// São as palavras que o jogo pode sortear como secreta — todas com 5 letras.
const List<String> palavrasGabarito = [
  'TERMO', // palavra de 5 letras
  'METRO', // palavra de 5 letras
  'CASAL', // palavra de 5 letras
  'PRATO', // palavra de 5 letras
  'LIVRO', // palavra de 5 letras
  'FESTA', // palavra de 5 letras
  'PORTA', // palavra de 5 letras
  'VERDE', // palavra de 5 letras
  'NOITE', // palavra de 5 letras
  'CARRO', // palavra de 5 letras
  'AMIGO', // palavra de 5 letras
  'PLANO', // palavra de 5 letras
  'MUNDO', // palavra de 5 letras
  'TEMPO', // palavra de 5 letras
  'BOLAR', // palavra de 5 letras
];

// Lista de palavras aceitas como CHUTE (tentativa do jogador).
// É um superconjunto do gabarito: tudo que é resposta também é chute válido,
// mais palavras extras que aceitamos como tentativa mas que nunca serão a secreta.
// O controller consulta esta lista para recusar palavra que não existe.
const List<String> palavrasValidas = [
  // todas do gabarito também são chutes válidos
  'TERMO', 'METRO', 'CASAL', 'PRATO', 'LIVRO',
  'FESTA', 'PORTA', 'VERDE', 'NOITE', 'CARRO',
  'AMIGO', 'PLANO', 'MUNDO', 'TEMPO', 'BOLAR',
  // chutes extras aceitos como tentativa (não entram no sorteio da resposta)
  'BOBOS', 'GATOS', 'PEDRA', 'LUGAR', 'FORTE',
  'CALOR', 'SALAS', 'MARES', 'TROCA', 'VAGAO',
  'TRILA', 'PISTA', 'LINHA', 'TRENS', 'PONTE',
];

// Escolhe a "palavra do dia": determinística, para que todos joguem a mesma palavra
// no mesmo dia (assim o ranking fica justo). Recebe o pool de onde sortear.
String palavraDoDia(List<String> pool) {
  // Conta quantos dias se passaram entre hoje e uma data fixa de referência.
  final dias = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
  // Usa o resto da divisão pelo tamanho da lista como índice: garante índice válido
  // e faz a palavra mudar a cada dia, repetindo o ciclo quando a lista acaba.
  return pool[dias % pool.length];
}

// Sorteia uma palavra qualquer do pool (usada no "jogar de novo", onde não importa
// ser a mesma para todos — é só para o jogador continuar treinando).
String palavraAleatoria(List<String> pool) {
  // Random().nextInt(n) devolve um índice entre 0 e n-1, sempre dentro da lista.
  return pool[Random().nextInt(pool.length)];
}
