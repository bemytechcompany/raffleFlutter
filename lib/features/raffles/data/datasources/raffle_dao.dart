import 'package:raffle/features/raffles/data/models/raffle_model.dart';
import 'package:raffle/features/raffles/data/datasources/raffle_local_datasource.dart';

class RaffleDao {
  final RaffleLocalDatasource localDatasource;

  RaffleDao({required this.localDatasource});

  Future<int> insertRaffle(RaffleModel raffle) async {
    return await localDatasource.insertRaffle(
      name: raffle.name,
      lotteryNumber: raffle.lotteryNumber,
      price: raffle.price,
      totalTickets: raffle.totalTickets,
      date: raffle.date,
      imagePath: raffle.imagePath,
      gameType: raffle.gameType,
      digitCount: raffle.digitCount,
    );
  }

  Future<List<RaffleModel>> getAllRaffles() async {
    final maps = await localDatasource.getAllRaffles();
    return maps.map((map) => RaffleModel.fromMap(map)).toList();
  }

  Future<void> updateRaffleStatus(int id, String newStatus) async {
    await localDatasource.updateRaffleStatus(id, newStatus);
  }

  Future<void> deleteRaffleById(int id) async {
    await localDatasource.deleteRaffle(id);
  }
}
