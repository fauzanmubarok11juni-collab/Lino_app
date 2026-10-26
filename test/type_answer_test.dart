import 'package:flashcard_app/features/study/data/type_answer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('huruf besar, tanda baca, dan apostrof diabaikan', () {
    expect(checkTypedAnswer('she doesnt like fish', "She doesn't like fish."),
        TypeVerdict.correct);
    expect(checkTypedAnswer('  I AM a teacher ', 'I am a teacher.'),
        TypeVerdict.correct);
  });

  test('jawaban alternatif diterima', () {
    expect(checkTypedAnswer('mahasiswa', 'siswa / mahasiswa'),
        TypeVerdict.correct);
    expect(checkTypedAnswer('padat', 'ramai; padat'), TypeVerdict.correct);
  });

  test('tanda hubung sama dengan spasi', () {
    expect(checkTypedAnswer('saudara laki laki', 'saudara laki-laki'),
        TypeVerdict.correct);
  });

  test('salah ketik: hampir benar untuk kata panjang saja', () {
    expect(checkTypedAnswer('meminjem', 'meminjam', allowTypos: true),
        TypeVerdict.close);
    expect(checkTypedAnswer('bukk', 'buku', allowTypos: true),
        TypeVerdict.wrong);
  });

  test('grammar tidak mentoleransi salah ketik', () {
    expect(checkTypedAnswer('go', 'goes'), TypeVerdict.wrong);
    expect(checkTypedAnswer('He live in Surabaya.', 'He lives in Surabaya.'),
        TypeVerdict.wrong);
  });

  test('jawaban kosong salah', () {
    expect(checkTypedAnswer('   ', 'goes', allowTypos: true),
        TypeVerdict.wrong);
  });
}