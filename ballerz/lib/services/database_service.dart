import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/player.dart';
import '../models/game.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final path = join(await getDatabasesPath(), 'football_app.db');
      return openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE players (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              position TEXT NOT NULL,
              pace INTEGER NOT NULL,
              shooting INTEGER NOT NULL,
              passing INTEGER NOT NULL,
              dribbling INTEGER NOT NULL,
              defending INTEGER NOT NULL,
              physical INTEGER NOT NULL,
              photoPath TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE games (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              team1Players TEXT NOT NULL,
              team2Players TEXT NOT NULL,
              team1Score INTEGER,
              team2Score INTEGER,
              winnerTeam INTEGER,
              playerOfGameId INTEGER,
              date TEXT NOT NULL,
              isCompleted INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE players ADD COLUMN photoPath TEXT');
          }
        },
      );
    } catch (e) {
      print('DB ERROR: $e');
      rethrow;
    }
  }
  // ─── Players ─────────────────────────────────────────────────────────────

  Future<int> insertPlayer(Player player) async {
    final db = await database;
    final map = player.toMap()..remove('id');
    return db.insert('players', map);
  }

  Future<List<Player>> getPlayers() async {
    final db = await database;
    final maps = await db.query('players', orderBy: 'name ASC');
    return maps.map(Player.fromMap).toList();
  }

  Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update('players', player.toMap(),
        where: 'id = ?', whereArgs: [player.id]);
  }

  Future<void> deletePlayer(int id) async {
    final db = await database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Games ────────────────────────────────────────────────────────────────

  Future<int> insertGame(Game game) async {
    final db = await database;
    final map = game.toMap()..remove('id');
    return db.insert('games', map);
  }

  Future<List<Game>> getGames() async {
    final db = await database;
    final maps = await db.query('games', orderBy: 'date DESC');
    return maps.map(Game.fromMap).toList();
  }

  Future<void> updateGame(Game game) async {
    final db = await database;
    await db
        .update('games', game.toMap(), where: 'id = ?', whereArgs: [game.id]);
  }

  Future<void> deleteGame(int id) async {
    final db = await database;
    await db.delete('games', where: 'id = ?', whereArgs: [id]);
  }
}
