import 'package:flashcard_app/features/settings/data/profile.dart';
import 'package:flashcard_app/shared/avatar_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nilai bawaan saat pengaturan kosong', () {
    final p = Profile.fromMap({});
    expect(p.onboarded, isFalse);
    expect(p.displayName, 'Teman');
    expect(p.dailyGoalXp, 200);
    expect(p.goalCards, 20);
    expect(p.theme, 'system');
  });

  test('membaca semua nilai yang tersimpan', () {
    final p = Profile.fromMap({
      'onboarded': '1',
      'name': ' Ayu ',
      'avatar': '5',
      'dailyGoalXp': '300',
      'theme': 'dark',
    });
    expect(p.onboarded, isTrue);
    expect(p.displayName, 'Ayu');
    expect(p.avatar, 5);
    expect(p.dailyGoalXp, 300);
    expect(p.theme, 'dark');
  });

  test('nilai yang tidak valid kembali ke bawaan', () {
    final p = Profile.fromMap({
      'avatar': '99',
      'dailyGoalXp': '123',
      'theme': 'neon',
    });
    expect(p.avatar, 0);
    expect(p.dailyGoalXp, 200);
    expect(p.theme, 'system');
  });

  test('jumlah avatar konsisten dengan daftar tampilan', () {
    expect(kAvatars.length, kAvatarCount);
  });
}