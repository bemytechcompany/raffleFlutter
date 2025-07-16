import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/raffle_model.dart';

class RaffleLocalDatasource {
  static final RaffleLocalDatasource instance = RaffleLocalDatasource._internal();
  static Database? _database;

  RaffleLocalDatasource._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'raffle.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE raffles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        lottery_number TEXT NOT NULL,
        price REAL NOT NULL,
        total_tickets INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        date TEXT NOT NULL,
        image_path TEXT,
        game_type TEXT NOT NULL,
        digit_count INTEGER NOT NULL,
        winning_number TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raffle_id INTEGER NOT NULL,
        number INTEGER NOT NULL,
        status TEXT NOT NULL,
        buyer_name TEXT,
        buyer_contact TEXT,
        FOREIGN KEY (raffle_id) REFERENCES raffles (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertRaffle({
    required String name,
    required String lotteryNumber,
    required double price,
    required int totalTickets,
    required DateTime date,
    String? imagePath,
    required String gameType,
    required int digitCount,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('raffles', {
      'name': name,
      'lottery_number': lotteryNumber,
      'price': price,
      'total_tickets': totalTickets,
      'status': 'active',
      'created_at': now,
      'updated_at': now,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'game_type': gameType,
      'digit_count': digitCount,
    });
  }

  Future<List<Map<String, dynamic>>> getAllRaffles() async {
    final db = await database;
    return await db.query('raffles', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getRaffleWithTickets(int id) async {
    final db = await database;
    final raffleList =
        await db.query('raffles', where: 'id = ?', whereArgs: [id]);
    if (raffleList.isEmpty) return null;

    final tickets = await db.query('tickets',
        where: 'raffle_id = ?', whereArgs: [id], orderBy: 'number ASC');
    return {
      'raffle': raffleList.first,
      'tickets': tickets,
    };
  }

  Future<void> updateTicket({
    required int ticketId,
    required String status,
    String? buyerName,
    String? buyerContact,
  }) async {
    final db = await database;
    final Map<String, dynamic> values = {
      'status': status,
    };
    
    // Only include buyer fields if status is not 'available'
    if (status != 'available') {
      values['buyer_name'] = buyerName;
      values['buyer_contact'] = buyerContact;
    } else {
      values['buyer_name'] = null;
      values['buyer_contact'] = null;
    }
    
    await db.update(
      'tickets',
      values,
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  Future<void> updateRaffleStatus(int raffleId, String newStatus) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'raffles',
      {
        'status': newStatus,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [raffleId],
    );
  }

  Future<void> updateWinningNumber(int raffleId, String winningNumber) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'raffles',
      {
        'winning_number': winningNumber,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [raffleId],
    );
  }

  /// Actualiza el número ganador y cambia el estado de la rifa a 'expired' para rifas tipo 'app'
  Future<void> setWinningNumberAndFinishRaffle(int raffleId, String winningNumber) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    // Obtener el tipo de juego de la rifa
    final raffleList = await db.query('raffles', where: 'id = ?', whereArgs: [raffleId]);
    if (raffleList.isEmpty) return;
    
    final gameType = raffleList.first['game_type'] as String;
    
    // Si es una rifa tipo 'app', cambiar el estado a 'expired'
    final Map<String, dynamic> updates = {
      'winning_number': winningNumber,
      'updated_at': now,
    };
    
    if (gameType == 'app' && winningNumber.isNotEmpty) {
      updates['status'] = 'expired';
    }
    
    await db.update(
      'raffles',
      updates,
      where: 'id = ?',
      whereArgs: [raffleId],
    );
  }

  Future<void> updateRaffle({
    required int raffleId,
    required String name,
    required String lotteryNumber,
    required double price,
    required DateTime date,
    String? imagePath,
    String? gameType,
    int? digitCount,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final Map<String, dynamic> values = {
      'name': name,
      'lottery_number': lotteryNumber,
      'price': price,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'updated_at': now,
    };

    if (gameType != null) values['game_type'] = gameType;
    if (digitCount != null) values['digit_count'] = digitCount;
    
    await db.update(
      'raffles',
      values,
      where: 'id = ?',
      whereArgs: [raffleId],
    );
  }

  Future<void> deleteRaffle(int raffleId) async {
    final db = await database;
    await db.delete('raffles', where: 'id = ?', whereArgs: [raffleId]);
  }

  Future<void> deleteRaffleById(int raffleId) async {
    final db = await database;
    await db.delete('raffles', where: 'id = ?', whereArgs: [raffleId]);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('tickets');
    await db.delete('raffles');
  }

  Future<void> insertTicket({
    required int raffleId,
    required int number,
    required String status,
    String? buyerName,
    String? buyerContact,
  }) async {
    final db = await database;
    await db.insert('tickets', {
      'raffle_id': raffleId,
      'number': number,
      'status': status,
      'buyer_name': buyerName,
      'buyer_contact': buyerContact,
    });
  }

  Future<int> insertRaffleModel(RaffleModel model) async {
    return await insertRaffle(
      name: model.name,
      lotteryNumber: model.lotteryNumber,
      price: model.price,
      totalTickets: model.totalTickets,
      date: model.date,
      imagePath: model.imagePath,
      gameType: model.gameType,
      digitCount: model.digitCount,
    );
  }
}
