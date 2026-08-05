import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/park_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('park_bulucu_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const nullableTextType = 'TEXT';
    const intType = 'INTEGER DEFAULT 0';

    await db.execute('''
      CREATE TABLE parked_cars (
        id $idType,
        plate $textType,
        latitude $doubleType,
        longitude $doubleType,
        timestamp $nullableTextType,
        note $nullableTextType,
        floorInfo $nullableTextType,
        carType $nullableTextType,
        ticketCode $nullableTextType,
        keyLocation $nullableTextType,
        isDelivered $intType,
        deliveredTimestamp $nullableTextType
      )
    ''');
  }

  Future<ParkedCar> insertPark(ParkedCar car) async {
    final db = await instance.database;
    final id = await db.insert('parked_cars', car.toMap());
    return ParkedCar(
      id: id,
      plate: car.plate,
      latitude: car.latitude,
      longitude: car.longitude,
      timestamp: car.timestamp,
      note: car.note,
      floorInfo: car.floorInfo,
      carType: car.carType,
      ticketCode: car.ticketCode,
      keyLocation: car.keyLocation,
      isDelivered: car.isDelivered,
      deliveredTimestamp: car.deliveredTimestamp,
    );
  }

  Future<List<ParkedCar>> getActiveParkedCars() async {
    final db = await instance.database;
    final result = await db.query(
      'parked_cars',
      where: 'isDelivered = 0',
      orderBy: 'id DESC',
    );
    return result.map((json) => ParkedCar.fromMap(json)).toList();
  }

  Future<List<ParkedCar>> getDeliveredCars() async {
    final db = await instance.database;
    final result = await db.query(
      'parked_cars',
      where: 'isDelivered = 1',
      orderBy: 'id DESC',
    );
    return result.map((json) => ParkedCar.fromMap(json)).toList();
  }

  Future<int> markAsDelivered(int id) async {
    final db = await instance.database;
    return await db.update(
      'parked_cars',
      {
        'isDelivered': 1,
        'deliveredTimestamp': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePark(int id) async {
    final db = await instance.database;
    return await db.delete(
      'parked_cars',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllParks() async {
    final db = await instance.database;
    return await db.delete('parked_cars');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
