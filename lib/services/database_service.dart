import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  // 싱글톤 패턴을 위한 private 생성자와 static 인스턴스
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  // 앱 전체에서 단 하나의 데이터베이스 인스턴스만 유지
  static Database? _database;

  // 데이터베이스 인스턴스를 가져오는 getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // 데이터베이스를 초기화하는 메서드
  Future<Database> _initDB() async {
    // 데이터베이스 경로를 가져옴
    String path = join(await getDatabasesPath(), 'chat_history.db');

    // 데이터베이스를 열거나 생성
    return await openDatabase(
      path,
      version: 1, // 데이터베이스 스키마 변경 시 버전 관리
      onCreate: _onCreate, // DB가 처음 생성될 때 실행될 함수
    );
  }

  // 데이터베이스 테이블을 생성하는 메서드
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL,
        content TEXT NOT NULL,
        sender TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // C: 메시지 저장
  Future<int> saveMessage(Map<String, dynamic> message) async {
    final db = await instance.database;
    return await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // R: 특정 uuid의 모든 메시지 기록 조회
  Future<List<Map<String, dynamic>>> getHistory(String uuid) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: 'uuid = ?',
      whereArgs: [uuid],
      orderBy: 'timestamp DESC', // ASC를 DESC로 변경하여 최신순으로 정렬
    );
  }
}
