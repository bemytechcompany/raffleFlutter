import 'package:raffle/features/raffles/data/datasources/raffle_local_datasource.dart';
import 'package:raffle/features/raffles/data/datasources/ticket_dao.dart';
import 'package:raffle/features/raffles/data/models/raffle_model.dart';
import 'package:raffle/features/raffles/data/models/ticket_model.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/repositories/raffle_repository.dart';

class RaffleRepositoryImpl implements RaffleRepository {
  final RaffleLocalDatasource raffleLocalDatasource;
  final TicketDao ticketDao;

  RaffleRepositoryImpl({
    required this.raffleLocalDatasource,
    required this.ticketDao,
  });

  @override
  Future<void> createRaffle(Raffle raffle) async {
    final raffleModel = RaffleModel.fromEntity(raffle);
    await raffleLocalDatasource.insertRaffleModel(raffleModel);
  }

  @override
  Future<void> createRaffleWithTickets(
      Raffle raffle, List<Ticket> tickets) async {
    final raffleModel = RaffleModel.fromEntity(raffle);
    final raffleId = await raffleLocalDatasource.insertRaffleModel(raffleModel);

    final ticketModels = tickets.map((ticket) {
      return TicketModel(
        id: 0,
        raffleId: raffleId,
        number: ticket.number,
        status: ticket.status,
        buyerName: ticket.buyerName,
        buyerContact: ticket.buyerContact,
      );
    }).toList();

    await ticketDao.insertTickets(ticketModels, raffleId);
  }

  @override
  Future<List<Raffle>> getAllRaffles() async {
    final maps = await raffleLocalDatasource.getAllRaffles();
    List<Raffle> raffles = [];

    for (final map in maps) {
      final raffle = RaffleModel.fromMap(map).toEntity();
      final tickets = await ticketDao.getTicketsByRaffleId(raffle.id!);
      raffles.add(raffle.copyWith(tickets: tickets));
    }

    return raffles;
  }

  @override
  Future<List<Ticket>> getTicketsByRaffle(int raffleId) async {
    final models = await ticketDao.getTicketsByRaffleId(raffleId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateRaffleStatus(int raffleId, String newStatus) async {
    await raffleLocalDatasource.updateRaffleStatus(raffleId, newStatus);
  }

  @override
  Future<void> updateTicket(Ticket ticket) async {
    final ticketModel = TicketModel.fromEntity(ticket);
    await ticketDao.updateTicket(ticketModel);
  }

  @override
  Future<void> deleteRaffleAndTickets(int raffleId) async {
    await raffleLocalDatasource.deleteRaffle(raffleId);
  }

  @override
  Future<void> updateRaffle(Raffle raffle) async {
    if (raffle.id == null) {
      throw Exception('Cannot update raffle without id');
    }
    
    await raffleLocalDatasource.updateRaffle(
      raffleId: raffle.id!,
      name: raffle.name,
      lotteryNumber: raffle.lotteryNumber,
      price: raffle.price,
      date: raffle.date,
      imagePath: raffle.imagePath,
    );
  }

  @override
  Future<Map<String, dynamic>?> getRaffleWithTickets(int raffleId) async {
    return await raffleLocalDatasource.getRaffleWithTickets(raffleId);
  }

  @override
  Future<void> setWinningNumberAndFinishRaffle(int raffleId, String winningNumber) async {
    await raffleLocalDatasource.setWinningNumberAndFinishRaffle(raffleId, winningNumber);
  }
}
