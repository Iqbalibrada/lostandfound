double hitungKemiripan(String a, String b) {
  a = a.toLowerCase().trim();
  b = b.toLowerCase().trim();

  if (a == b) return 100.0;
  if (a.isEmpty || b.isEmpty) return 0.0;

  final wordsA = a.split(RegExp(r'\s+'));
  final wordsB = b.split(RegExp(r'\s+'));

  final shorter = wordsA.length <= wordsB.length ? wordsA : wordsB;
  final longer = wordsA.length <= wordsB.length ? wordsB : wordsA;

  int matches = 0;
  for (final word in shorter) {
    if (longer.contains(word)) matches++;
  }

  return (matches / shorter.length) * 100.0;
}

String gabungTeks(List<dynamic> details) {
  return details
      .map((d) => d['field_value']?.toString() ?? '')
      .where((v) => v.isNotEmpty)
      .join(' ');
}
