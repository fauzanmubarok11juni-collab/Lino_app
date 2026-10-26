import 'dart:math';
import '../../../core/database/app_database.dart';

enum TypeVerdict { correct, close, wrong }

final _apostrophes = RegExp("[’'`´]");
final _punct = RegExp(r'[.,!?;:()\[\]\-"“”]');

/// Huruf kecil, tanpa tanda baca dan apostrof, spasi dirapikan.
String normalizeAnswer(String s) => s
    .toLowerCase()
    .replaceAll(_apostrophes, '')
    .replaceAll(_punct, ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Jawaban alternatif dipisah " / ", ";" atau baris baru.
List<String> acceptedAnswers(String expected) => expected
    .split(RegExp(r'\s+/\s+|;|\n'))
    .map(normalizeAnswer)
    .where((a) => a.isNotEmpty)
    .toList();

/// Salah ketik hanya ditoleransi untuk kosakata dan kartu manual.
bool allowTyposFor(String questionType) =>
    questionType == 'V' || questionType == 'basic';

/// Jawaban yang diharapkan: kolom jawaban, atau sisi belakang untuk kartu manual.
String expectedOf(FlashCard c) =>
    c.answer.trim().isNotEmpty ? c.answer : c.back;

int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = min(min(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + cost);
    }
    prev = cur;
  }
  return prev[b.length];
}

TypeVerdict checkTypedAnswer(
  String typed,
  String expected, {
  bool allowTypos = false,
}) {
  final t = normalizeAnswer(typed);
  if (t.isEmpty) return TypeVerdict.wrong;

  var close = false;
  for (final a in acceptedAnswers(expected)) {
    if (a == t) return TypeVerdict.correct;
    if (!allowTypos) continue;
    final tolerance = a.length <= 4 ? 0 : (a.length <= 8 ? 1 : 2);
    final d = editDistance(t, a);
    if (d > 0 && d <= tolerance) close = true;
  }
  return close ? TypeVerdict.close : TypeVerdict.wrong;
}