import 'dart:math';

enum QuestKind { earnXp, finishLessons, perfectLesson, learnWords, combo }

class QuestDef {
  const QuestDef(this.id, this.kind, this.target, this.title, this.gems);

  final String id;
  final QuestKind kind;
  final int target;
  final String title;
  final int gems;
}

/// Three quests per day, picked deterministically from the date.
List<QuestDef> questsForDay(String dayKey) {
  final rnd = Random(dayKey.hashCode);
  final xp = [20, 30, 50][rnd.nextInt(3)];
  final lessons = [2, 3][rnd.nextInt(2)];
  final third = rnd.nextInt(3);
  return [
    QuestDef('xp$xp', QuestKind.earnXp, xp, 'Earn $xp XP', 10),
    QuestDef('lessons$lessons', QuestKind.finishLessons, lessons,
        'Finish $lessons lessons', 15),
    switch (third) {
      0 => const QuestDef('perfect', QuestKind.perfectLesson, 1,
          'Finish a lesson with no mistakes', 20),
      1 => const QuestDef('words10', QuestKind.learnWords, 10,
          'Answer 10 words correctly', 15),
      _ => const QuestDef(
          'combo8', QuestKind.combo, 8, 'Get 8 correct in a row', 20),
    },
  ];
}

class AchievementDef {
  const AchievementDef(
      this.id, this.title, this.emoji, this.description, this.gems);

  final String id;
  final String title;
  final String emoji;
  final String description;
  final int gems;
}

const achievementDefs = [
  AchievementDef('first', 'First Steps', '🌱', 'Finish your first lesson', 10),
  AchievementDef('lessons10', 'Dedicated', '📚', 'Finish 10 lessons', 25),
  AchievementDef('lessons50', 'Scholar', '🎓', 'Finish 50 lessons', 80),
  AchievementDef('streak3', 'On a Roll', '🔥', 'Reach a 3 day streak', 15),
  AchievementDef('streak7', 'Week Warrior', '⚔️', 'Reach a 7 day streak', 40),
  AchievementDef('streak30', 'Unstoppable', '🏆', 'Reach a 30 day streak', 150),
  AchievementDef('xp500', 'Rising Star', '⭐', 'Earn 500 XP', 30),
  AchievementDef('xp5000', 'Legend', '👑', 'Earn 5000 XP', 200),
  AchievementDef('perfect5', 'Flawless', '💎', 'Finish 5 perfect lessons', 50),
  AchievementDef('words50', 'Wordsmith', '📖', 'Learn 50 words', 40),
  AchievementDef('stories3', 'Story Time', '🎭', 'Finish 3 stories', 30),
  AchievementDef('promo', 'Climber', '🚀', 'Get promoted in a league', 60),
  AchievementDef('levelA1', 'A1 Beginner', '🌱', 'Pass the A1 checkpoint', 50),
  AchievementDef('levelA2', 'A2 Elementary', '🌿', 'Pass the A2 checkpoint', 75),
  AchievementDef('levelB1', 'B1 Intermediate', '🌳', 'Pass the B1 checkpoint', 100),
  AchievementDef('levelB2', 'B2 Upper Intermediate', '🏔️', 'Pass the B2 checkpoint', 150),
  AchievementDef('levelC1', 'C1 Advanced', '🚀', 'Pass the C1 checkpoint', 200),
  AchievementDef('levelC2', 'C2 Mastery', '👑', 'Pass the C2 checkpoint', 300),
];
