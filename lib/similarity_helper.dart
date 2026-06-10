import 'dart:math';

double hitungKemiripan(String a, String b) {
  a = a.toLowerCase().trim();
  b = b.toLowerCase().trim();

  if (a == b) return 100.0;
  if (a.isEmpty || b.isEmpty) return 0.0;

  final maxLen = max(a.length, b.length);
  if (maxLen == 0) return 100.0;

  final dist = _levenshtein(a, b);
  return ((maxLen - dist) / maxLen) * 100.0;
}

int _levenshtein(String a, String b) {
  final m = a.length;
  final n = b.length;

  List<int> prev = List.generate(n + 1, (i) => i);
  List<int> curr = List.filled(n + 1, 0);

  for (int i = 1; i <= m; i++) {
    curr[0] = i;
    for (int j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = [
        prev[j] + 1,
        curr[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    final temp = prev;
    prev = curr;
    curr = temp;
  }

  return prev[n];
}

String gabungTeks(List<dynamic> details) {
  return details
      .map((d) => d['field_value']?.toString() ?? '')
      .where((v) => v.isNotEmpty)
      .join(' ');
}
