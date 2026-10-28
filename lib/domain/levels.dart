/// The six CEFR levels the course covers, in learning order.
class CefrLevel {
  const CefrLevel(this.id, this.name, this.emoji, this.blurb);

  final String id;
  final String name;
  final String emoji;
  final String blurb;
}

const cefrLevels = [
  CefrLevel('A1', 'Beginner', '🌱', 'Greetings, basics and simple everyday talk'),
  CefrLevel('A2', 'Elementary', '🌿', 'Past, future, routines and practical situations'),
  CefrLevel('B1', 'Intermediate', '🌳', 'Tell stories, give opinions, handle most trips and work'),
  CefrLevel('B2', 'Upper intermediate', '🏔️', 'Argue, hypothesise and follow complex texts'),
  CefrLevel('C1', 'Advanced', '🚀', 'Fluent, precise and flexible use of the language'),
  CefrLevel('C2', 'Mastery', '👑', 'Near-native control of style and nuance'),
];

CefrLevel levelById(String id) =>
    cefrLevels.firstWhere((l) => l.id == id, orElse: () => cefrLevels.first);

/// Share of checkpoint questions that must be right to pass.
const checkpointPassMark = 0.8;

/// Number of questions in a level checkpoint.
const checkpointQuestions = 20;

/// XP and gems for a checkpoint attempt.
const checkpointXp = 30;
const checkpointGems = 40;
