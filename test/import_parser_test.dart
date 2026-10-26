import 'package:flashcard_app/features/import/data/import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('judul menentukan jenis deck dan nama', () {
    final s = parseImportText(
        '# Vocabulary: Basic\nV | book | buku\n# Grammar: To Be\nFIB | I ___ a boy. | am');
    expect(s.length, 2);
    expect(s[0].deckKind, 'vocab');
    expect(s[0].name, 'Basic');
    expect(s[1].deckKind, 'grammar');
  });

  test('format 5 kolom terbaca lengkap', () {
    final c = parseImportText(
            '# Grammar: X\nFIB | She ___ to school. (go) | goes | He/she/it + s. | go; going')[0]
        .cards[0];
    expect(c.answer, 'goes');
    expect(c.explanation, 'He/she/it + s.');
    expect(c.choices, ['go', 'going']);
    expect(c.front, startsWith('Lengkapi kalimat:'));
    expect(c.back, 'goes\nHe/she/it + s.');
    expect(c.practiceWarning, isNull);
  });

  test('format 3 kolom lama tetap jadi flashcard', () {
    final c = parseImportText(
            '# Grammar: X\nTR | Dia tinggal di Surabaya. | He lives in Surabaya.')[0]
        .cards[0];
    expect(c.isValid, isTrue);
    expect(c.choices, isEmpty);
    expect(c.practiceWarning, isNotNull);
  });

  test('jawaban sama dengan pengecoh diberi peringatan', () {
    final c = parseImportText('# Grammar: X\nMC | He ___ a boy. | is | | is; are')[0]
        .cards[0];
    expect(c.practiceWarning, isNotNull);
  });

  test('baris yang terpotong disambung', () {
    final s = parseImportText(
        '# Grammar: X\nFIB | She ___ to school\nevery day. | goes.');
    expect(s[0].cards[0].front, contains('She ___ to school every day.'));
    expect(s[0].cards[0].answer, 'goes.');
  });

  test('// menjadi baris baru dan MC tidak diberi petunjuk', () {
    final s = parseImportText('# Grammar: X\nMC | Line one // line two | is | | am; are');
    expect(s[0].cards[0].front, 'Line one\nline two');
  });

  test('kolom ekstra digabung ke penjelasan, bukan hilang', () {
    final c = parseImportText('# Grammar: X\nTR | a | b | c')[0].cards[0];
    expect(c.answer, 'b');
    expect(c.explanation, 'c');
  });
}