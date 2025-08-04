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
      version: 2,
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
