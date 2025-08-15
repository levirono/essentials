import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class RecentPdf {
  final int? id;
  final String filePath;
  final int lastPage;
  final DateTime lastOpened;

  RecentPdf({
    this.id,
    required this.filePath,
    required this.lastPage,
    required this.lastOpened,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'lastPage': lastPage,
      'lastOpened': lastOpened.toIso8601String(),
    };
  }

  factory RecentPdf.fromMap(Map<String, dynamic> map) {
    return RecentPdf(
      id: map['id'],
      filePath: map['filePath'],
      lastPage: map['lastPage'],
      lastOpened: DateTime.parse(map['lastOpened']),
    );
  }
}

class AnalyzedSentence {
  final int? id;
  final String text;
  final Map<String, dynamic> analysisResults;
  final DateTime analyzedAt;
  final String? title; // Optional title for the analysis

  AnalyzedSentence({
    this.id,
    required this.text,
    required this.analysisResults,
    required this.analyzedAt,
    this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'analysisResults': jsonEncode(analysisResults),
      'analyzedAt': analyzedAt.toIso8601String(),
      'title': title,
    };
  }

  factory AnalyzedSentence.fromMap(Map<String, dynamic> map) {
    return AnalyzedSentence(
      id: map['id'],
      text: map['text'],
      analysisResults: jsonDecode(map['analysisResults']),
      analyzedAt: DateTime.parse(map['analyzedAt']),
      title: map['title'],
    );
  }
}

class BrainTeaser {
  final int? id;
  final String question;
  final String answer;
  final String? explanation;
  final String category;
  final int difficulty;
  final DateTime createdAt;
  final bool isActive;

  BrainTeaser({
    this.id,
    required this.question,
    required this.answer,
    this.explanation,
    required this.category,
    required this.difficulty,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'explanation': explanation,
      'category': category,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory BrainTeaser.fromMap(Map<String, dynamic> map) {
    return BrainTeaser(
      id: map['id'],
      question: map['question'],
      answer: map['answer'],
      explanation: map['explanation'],
      category: map['category'],
      difficulty: map['difficulty'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }
}

class FocusSession {
  final int? id;
  final DateTime startTime;
  late final DateTime? endTime;
  final Duration duration;
  final String sessionType; // 'focus', 'break', 'long_break'
  late final bool isCompleted;
  late final String? notes;
  final DateTime createdAt;

  FocusSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.sessionType,
    this.isCompleted = false,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inSeconds,
      'sessionType': sessionType,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      duration: Duration(seconds: map['duration']),
      sessionType: map['sessionType'],
      isCompleted: map['isCompleted'] == 1,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class FocusTimerSettings {
  final int? id;
  final int focusMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int cyclesBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final DateTime updatedAt;

  FocusTimerSettings({
    this.id,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.cyclesBeforeLongBreak,
    this.autoStartBreaks = true,
    this.autoStartFocus = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'focusMinutes': focusMinutes,
      'breakMinutes': breakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'cyclesBeforeLongBreak': cyclesBeforeLongBreak,
      'autoStartBreaks': autoStartBreaks ? 1 : 0,
      'autoStartFocus': autoStartFocus ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FocusTimerSettings.fromMap(Map<String, dynamic> map) {
    return FocusTimerSettings(
      id: map['id'],
      focusMinutes: map['focusMinutes'],
      breakMinutes: map['breakMinutes'],
      longBreakMinutes: map['longBreakMinutes'],
      cyclesBeforeLongBreak: map['cyclesBeforeLongBreak'],
      autoStartBreaks: map['autoStartBreaks'] == 1,
      autoStartFocus: map['autoStartFocus'] == 1,
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'essentials.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recent_pdfs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filePath TEXT NOT NULL,
        lastPage INTEGER NOT NULL,
        lastOpened TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE highlights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filePath TEXT NOT NULL,
        page INTEGER NOT NULL,
        highlightData TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE extracted_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filePath TEXT NOT NULL,
        page INTEGER NOT NULL,
        imageData TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE analyzed_sentences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        analysisResults TEXT NOT NULL,
        analyzedAt TEXT NOT NULL,
        title TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE mind_maps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE brain_teasers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        explanation TEXT,
        category TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime TEXT NOT NULL,
        endTime TEXT,
        duration INTEGER NOT NULL,
        sessionType TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE focus_timer_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        focusMinutes INTEGER NOT NULL,
        breakMinutes INTEGER NOT NULL,
        longBreakMinutes INTEGER NOT NULL,
        cyclesBeforeLongBreak INTEGER NOT NULL,
        autoStartBreaks INTEGER NOT NULL DEFAULT 1,
        autoStartFocus INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE analyzed_sentences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT NOT NULL,
          analysisResults TEXT NOT NULL,
          analyzedAt TEXT NOT NULL,
          title TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE mind_maps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          data TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE brain_teasers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          question TEXT NOT NULL,
          answer TEXT NOT NULL,
          explanation TEXT,
        category TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE focus_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          startTime TEXT NOT NULL,
          endTime TEXT,
          duration INTEGER NOT NULL,
          sessionType TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE focus_timer_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          focusMinutes INTEGER NOT NULL,
          breakMinutes INTEGER NOT NULL,
          longBreakMinutes INTEGER NOT NULL,
          cyclesBeforeLongBreak INTEGER NOT NULL,
          autoStartBreaks INTEGER NOT NULL DEFAULT 1,
          autoStartFocus INTEGER NOT NULL DEFAULT 0,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
  }

  // Mind Map methods
  Future<int> insertMindMap(String title, Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('mind_maps', {
      'title': title,
      'data': jsonEncode(data),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<int> updateMindMap(
    int id,
    String title,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'mind_maps',
      {'title': title, 'data': jsonEncode(data), 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getMindMaps() async {
    final db = await database;
    return await db.query('mind_maps', orderBy: 'updatedAt DESC');
  }

  Future<Map<String, dynamic>?> getMindMapById(int id) async {
    final db = await database;
    final maps = await db.query('mind_maps', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final map = maps.first;
      return {
        'id': map['id'],
        'title': map['title'],
        'data': jsonDecode(map['data'] as String),
        'createdAt': map['createdAt'],
        'updatedAt': map['updatedAt'],
      };
    }
    return null;
  }

  Future<void> deleteMindMap(int id) async {
    final db = await database;
    await db.delete('mind_maps', where: 'id = ?', whereArgs: [id]);
  }

  // Brain Teaser methods
  Future<int> insertBrainTeaser(BrainTeaser teaser) async {
    final db = await database;
    return await db.insert('brain_teasers', teaser.toMap());
  }

  Future<int> updateBrainTeaser(BrainTeaser teaser) async {
    final db = await database;
    return await db.update(
      'brain_teasers',
      teaser.toMap(),
      where: 'id = ?',
      whereArgs: [teaser.id],
    );
  }

  Future<List<BrainTeaser>> getBrainTeasers({String? category, int? difficulty}) async {
    final db = await database;
    String whereClause = 'isActive = 1';
    List<dynamic> whereArgs = [];
    
    if (category != null && category.isNotEmpty) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }
    
    if (difficulty != null) {
      whereClause += ' AND difficulty = ?';
      whereArgs.add(difficulty);
    }
    
    final maps = await db.query(
      'brain_teasers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => BrainTeaser.fromMap(map)).toList();
  }

  Future<BrainTeaser?> getBrainTeaserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'brain_teasers',
      where: 'id = ? AND isActive = 1',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BrainTeaser.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteBrainTeaser(int id) async {
    final db = await database;
    await db.update(
      'brain_teasers',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getBrainTeaserCategories() async {
    final db = await database;
    final maps = await db.query(
      'brain_teasers',
      columns: ['DISTINCT category'],
      where: 'isActive = 1',
    );
    return maps.map((map) => map['category'] as String).toList();
  }

  Future<void> insertSampleBrainTeasers() async {
    final db = await database;
    final existing = await db.query('brain_teasers');
    if (existing.isEmpty) {
      final sampleTeasers = [
        BrainTeaser(
          question: 'What has keys, but no locks; space, but no room; and you can enter, but not go in?',
          answer: 'keyboard',
          explanation: 'A keyboard has keys, space bar, and you can enter text but not physically go inside it.',
          category: 'Riddles',
          difficulty: 2,
          createdAt: DateTime.now(),
        ),
        BrainTeaser(
          question: 'I am not alive, but I grow; I don\'t have lungs, but I need air; I don\'t have a mouth, but water kills me. What am I?',
          answer: 'fire',
          explanation: 'Fire grows, needs oxygen to burn, and is extinguished by water.',
          category: 'Riddles',
          difficulty: 1,
          createdAt: DateTime.now(),
        ),
        BrainTeaser(
          question: 'What number comes next in the sequence: 2, 6, 12, 20, 30, ?',
          answer: '42',
          explanation: 'The difference between consecutive terms increases by 2: 4, 6, 8, 10, 12. So 30 + 12 = 42.',
          category: 'Mathematics',
          difficulty: 3,
          createdAt: DateTime.now(),
        ),
        BrainTeaser(
          question: 'If you have 3 apples and you take away 2, how many do you have?',
          answer: '2',
          explanation: 'You took away 2 apples, so you have 2 apples.',
          category: 'Logic',
          difficulty: 1,
          createdAt: DateTime.now(),
        ),
        BrainTeaser(
          question: 'What word becomes shorter when you add two letters to it?',
          answer: 'short',
          explanation: 'Adding "er" to "short" makes "shorter", which is longer, but the question asks what becomes shorter.',
          category: 'Word Play',
          difficulty: 2,
          createdAt: DateTime.now(),
        ),
      ];
      
      for (final teaser in sampleTeasers) {
        await db.insert('brain_teasers', teaser.toMap());
      }
    }
  }

  // Focus Timer methods
  Future<int> insertFocusSession(FocusSession session) async {
    final db = await database;
    return await db.insert('focus_sessions', session.toMap());
  }

  Future<int> updateFocusSession(FocusSession session) async {
    final db = await database;
    return await db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<FocusSession>> getFocusSessions({
    DateTime? startDate,
    DateTime? endDate,
    String? sessionType,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND startTime >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND startTime <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (sessionType != null) {
      whereClause += ' AND sessionType = ?';
      whereArgs.add(sessionType);
    }
    
    final maps = await db.query(
      'focus_sessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => FocusSession.fromMap(map)).toList();
  }

  Future<FocusSession?> getFocusSessionById(int id) async {
    final db = await database;
    final maps = await db.query(
      'focus_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return FocusSession.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteFocusSession(int id) async {
    final db = await database;
    await db.delete('focus_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<FocusTimerSettings?> getFocusTimerSettings() async {
    final db = await database;
    final maps = await db.query('focus_timer_settings', orderBy: 'updatedAt DESC', limit: 1);
    if (maps.isNotEmpty) {
      return FocusTimerSettings.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertOrUpdateFocusTimerSettings(FocusTimerSettings settings) async {
    final db = await database;
    final existing = await db.query('focus_timer_settings');
    if (existing.isNotEmpty) {
      return await db.update(
        'focus_timer_settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('focus_timer_settings', settings.toMap());
    }
  }

  Future<void> insertDefaultFocusTimerSettings() async {
    final db = await database;
    final existing = await db.query('focus_timer_settings');
    if (existing.isEmpty) {
      final defaultSettings = FocusTimerSettings(
        focusMinutes: 25,
        breakMinutes: 5,
        longBreakMinutes: 15,
        cyclesBeforeLongBreak: 4,
        autoStartBreaks: true,
        autoStartFocus: false,
        updatedAt: DateTime.now(),
      );
      await db.insert('focus_timer_settings', defaultSettings.toMap());
    }
  }

  Future<Map<String, dynamic>> getFocusTimerStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    // Get total focus time
    final focusSessions = await getFocusSessions(
      startDate: startDate,
      endDate: endDate,
      sessionType: 'focus',
    );
    
    int totalFocusMinutes = 0;
    int completedSessions = 0;
    int totalSessions = focusSessions.length;
    
    for (final session in focusSessions) {
      if (session.isCompleted) {
        totalFocusMinutes += session.duration.inMinutes;
        completedSessions++;
      }
    }
    
    // Get daily stats for the last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    final dailyStats = <String, int>{};
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyStats[dayKey] = 0;
    }
    
    final recentSessions = await getFocusSessions(
      startDate: sevenDaysAgo,
      endDate: now,
      sessionType: 'focus',
    );
    
    for (final session in recentSessions) {
      if (session.isCompleted) {
        final dayKey = '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';
        if (dailyStats.containsKey(dayKey)) {
          dailyStats[dayKey] = dailyStats[dayKey]! + session.duration.inMinutes;
        }
      }
    }
    
    return {
      'totalFocusMinutes': totalFocusMinutes,
      'completedSessions': completedSessions,
      'totalSessions': totalSessions,
      'dailyStats': dailyStats,
      'averageSessionLength': totalSessions > 0 ? totalFocusMinutes / totalSessions : 0,
    };
  }

  Future<void> insertOrUpdateRecentPdf(RecentPdf pdf) async {
    final db = await database;
    // If filePath exists, update; else insert
    final existing = await db.query(
      'recent_pdfs',
      where: 'filePath = ?',
      whereArgs: [pdf.filePath],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'recent_pdfs',
        pdf.toMap(),
        where: 'filePath = ?',
        whereArgs: [pdf.filePath],
      );
    } else {
      await db.insert('recent_pdfs', pdf.toMap());
    }
  }

  Future<List<RecentPdf>> getRecentPdfs() async {
    final db = await database;
    final maps = await db.query('recent_pdfs', orderBy: 'lastOpened DESC');
    return maps.map((map) => RecentPdf.fromMap(map)).toList();
  }

  Future<void> deleteRecentPdf(String filePath) async {
    final db = await database;
    await db.delete(
      'recent_pdfs',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
  }

  // Analyzed Sentence methods
  Future<int> insertAnalyzedSentence({
    required String text,
    required Map<String, dynamic> analysisResults,
    String? title,
  }) async {
    final db = await database;
    final now = DateTime.now();
    
    final analyzedSentence = AnalyzedSentence(
      text: text,
      analysisResults: analysisResults,
      analyzedAt: now,
      title: title,
    );
    
    return await db.insert('analyzed_sentences', analyzedSentence.toMap());
  }

  Future<List<AnalyzedSentence>> getAnalyzedSentences() async {
    final db = await database;
    final maps = await db.query('analyzed_sentences', orderBy: 'analyzedAt DESC');
    return maps.map((map) => AnalyzedSentence.fromMap(map)).toList();
  }

  Future<void> deleteAnalyzedSentence(int id) async {
    final db = await database;
    await db.delete('analyzed_sentences', where: 'id = ?', whereArgs: [id]);
  }

  // Highlight methods
  Future<void> insertHighlight(
    String filePath,
    int page,
    String highlightData,
  ) async {
    final db = await database;
    await db.insert('highlights', {
      'filePath': filePath,
      'page': page,
      'highlightData': highlightData,
    });
  }

  Future<List<Map<String, dynamic>>> getHighlights(String filePath) async {
    final db = await database;
    return await db.query(
      'highlights',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
  }

  // Extracted image methods
  Future<void> insertExtractedImage(
    String filePath,
    int page,
    String imageData,
  ) async {
    final db = await database;
    await db.insert('extracted_images', {
      'filePath': filePath,
      'page': page,
      'imageData': imageData,
    });
  }

  Future<List<Map<String, dynamic>>> getExtractedImages(String filePath) async {
    final db = await database;
    return await db.query(
      'extracted_images',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
  }
}
