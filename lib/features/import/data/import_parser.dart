class ParsedCard {
  ParsedCard({
    required this.type,
    required this.front,
    required this.answer,
    this.explanation = '',
    List<String>? choices,
  }) : choices = choices ?? [];

  final String type;
  String front;
  String answer;
  String explanation;
  List<String> choices;

  /// Isi sisi belakang flashcard.
  String get back => explanation.isEmpty ? answer : '$answer\n$explanation';

  bool get isValid => front.trim().isNotEmpty && answer.trim().isNotEmpty;

  /// null = siap dipakai di latihan. Selain itu = alasan hanya jadi flashcard.
  String? get practiceWarning {
    switch (type) {
      case 'V':
        return null; // pengecoh dibuat otomatis dari kartu lain
      case 'ORD':
        return answer.trim().split(RegExp(r'\s+')).length < 2
            ? 'Jawaban terlalu pendek untuk disusun'
            : null;
      default:
        if (choices.length < 2) {
          return 'Pengecoh kurang dari 2, hanya jadi flashcard';
        }
        final a = answer.trim().toLowerCase();
        if (choices.any((c) => c.trim().toLowerCase() == a)) {
          return 'Jawaban sama dengan salah satu pengecoh';
        }
        return null;
    }
  }
}

class ParsedSection {
  ParsedSection({required this.name, required this.deckKind});
  final String name;
  final String deckKind; // 'vocab' atau 'grammar'
  final List<ParsedCard> cards = [];
}

const _prefixes = {
  'FIB': 'Lengkapi kalimat:',
  'ERR': 'Perbaiki kesalahan:',
  'TR': 'Terjemahkan:',
  'ORD': 'Susun kalimat:',
  'TRF': 'Ubah bentuk kalimat:',
  'IRR': 'Bentuk kata kerja:',
};

final _cardLine = RegExp(r'^(V|FIB|MC|ERR|TR|ORD|TRF|IRR)\s*\|');
final _namePrefix =
    RegExp(r'^(vocabulary|vocab|grammar)\s*:\s*', caseSensitive: false);
final _newline = RegExp(r'\s*//\s*');

List<ParsedSection> parseImportText(String raw) {
  // 1. Gabungkan baris yang terpotong menjadi satu baris logis
  final logical = <String>[];
  for (final l in raw.replaceAll('\u00A0', ' ').split(RegExp(r'\r?\n'))) {
    final line = l.trim();
    if (line.isEmpty) continue;
    if (logical.isEmpty || line.startsWith('#') || _cardLine.hasMatch(line)) {
      logical.add(line);
    } else {
      logical[logical.length - 1] = '${logical.last} $line';
    }
  }

  // 2. Bentuk bagian (deck) dan kartu
  final sections = <ParsedSection>[];
  ParsedSection? current;

  for (final line in logical) {
    if (line.startsWith('#')) {
      final title = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
      final kind =
          title.toLowerCase().startsWith('vocab') ? 'vocab' : 'grammar';
      var name = title.replaceFirst(_namePrefix, '').trim();
      if (name.isEmpty) name = title;
      if (name.length > 100) name = name.substring(0, 100);
      current = ParsedSection(name: name, deckKind: kind);
      sections.add(current);
      continue;
    }
    if (!_cardLine.hasMatch(line)) continue;

    // JENIS | soal | jawaban | penjelasan | pengecoh1; pengecoh2
    final parts = line.split('|');
    final type = parts[0].trim().toUpperCase();
    var front = parts.length > 1 ? parts[1].trim() : '';
    final answer = parts.length > 2 ? parts[2].trim() : '';
    final explanation = parts.length > 3 ? parts[3].trim() : '';
    final choices = parts.length > 4
        ? parts
            .sublist(4)
            .join('|')
            .split(';')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList()
        : <String>[];

    front = front.replaceAll(_newline, '\n');
    final prefix = _prefixes[type];
    if (prefix != null && front.isNotEmpty) front = '$prefix\n$front';

    if (current == null) {
      current = ParsedSection(name: 'Impor', deckKind: 'grammar');
      sections.add(current);
    }
    current.cards.add(ParsedCard(
      type: type,
      front: front,
      answer: answer.replaceAll(_newline, '\n'),
      explanation: explanation.replaceAll(_newline, '\n'),
      choices: choices,
    ));
  }

  return sections.where((s) => s.cards.isNotEmpty).toList();
}