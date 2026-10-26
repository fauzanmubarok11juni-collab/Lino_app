import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Decks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get kind => text().withDefault(const Constant('vocab'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('FlashCard')
class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deckId =>
      integer().references(Decks, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()();
  TextColumn get back => text()();

  // Data latihan soal
  TextColumn get questionType => text().withDefault(const Constant('basic'))();
  TextColumn get answer => text().withDefault(const Constant(''))();
  TextColumn get choices => text().withDefault(const Constant(''))(); // JSON
  TextColumn get explanation => text().withDefault(const Constant(''))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  // Data spaced repetition (SM-2)
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId =>
      integer().references(Cards, #id, onDelete: KeyAction.cascade)();
  IntColumn get rating => integer()(); // 0=Lagi, 1=Sulit, 2=Baik, 3=Mudah
  DateTimeColumn get reviewedAt => dateTime().withDefault(currentDateAndTime)();
}

class PracticeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId =>
      integer().references(Cards, #id, onDelete: KeyAction.cascade)();
  BoolColumn get correct => boolean()();
  DateTimeColumn get practicedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// BARU: pengaturan dan profil (pasangan kunci-nilai).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
    tables: [Decks, Cards, ReviewLogs, PracticeLogs, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'flashcard'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(decks, decks.kind);
          if (from < 3) {
            await m.addColumn(cards, cards.questionType);
            await m.addColumn(cards, cards.answer);
            await m.addColumn(cards, cards.choices);
            await m.addColumn(cards, cards.explanation);
            await m.createTable(practiceLogs);
          }
          if (from < 4) await m.addColumn(cards, cards.isFavorite);
          if (from < 5) await m.createTable(appSettings);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}