const kDailyGoals = [100, 200, 300, 400];
const kAvatarCount = 8;
const kThemes = ['system', 'light', 'dark'];

class Profile {
  const Profile({
    this.onboarded = false,
    this.name = '',
    this.avatar = 0,
    this.dailyGoalXp = 200,
    this.language = 'en',
    this.theme = 'system',
  });

  final bool onboarded;
  final String name;
  final int avatar;
  final int dailyGoalXp;
  final String language;
  final String theme; // system | light | dark

  String get displayName => name.trim().isEmpty ? 'Teman' : name.trim();

  /// Perkiraan jumlah kartu per hari (satu kartu benar sekitar 10 XP).
  int get goalCards => dailyGoalXp ~/ 10;

  factory Profile.fromMap(Map<String, String> m) {
    final goal = int.tryParse(m['dailyGoalXp'] ?? '');
    final avatar = int.tryParse(m['avatar'] ?? '');
    return Profile(
      onboarded: m['onboarded'] == '1',
      name: m['name'] ?? '',
      avatar:
          (avatar != null && avatar >= 0 && avatar < kAvatarCount) ? avatar : 0,
      dailyGoalXp: kDailyGoals.contains(goal) ? goal! : 200,
      language: m['language'] ?? 'en',
      theme: kThemes.contains(m['theme']) ? m['theme']! : 'system',
    );
  }
}