import 'package:raffle/core/pagination/paged.dart';
import 'package:raffle/features/raffles/data/datasources/raffle_local_datasource.dart';
import 'package:raffle/features/raffles/data/models/raffle_model.dart';
import 'package:raffle/features/raffles/data/models/ticket_model.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/raffle_details.dart';
import 'package:raffle/features/raffles/domain/entities/raffle_summary.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/entities/ticket_counts.dart';
import 'package:raffle/features/raffles/domain/repositories/raffle_repository.dart';

class RaffleRepositoryImpl implements RaffleRepository {
  /// Rifas por página en el listado.
  static const int defaultRafflePageSize = 20;

  /// Boletos por página en el grid del detalle.
  static const int defaultTicketPageSize = 100;

  final RaffleLocalDatasource raffleLocalDatasource;

  RaffleRepositoryImpl({required this.raffleLocalDatasource});

  @override
  Future<Paged<RaffleSummary>> getRaffleSummaries({
    String? search,
    String? status,
    int page = 0,
    int pageSize = defaultRafflePageSize,
  }) {
    return _pageOfSummaries(
      inTrash: false,
      search: search,
      status: status,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Paged<RaffleSummary>> getTrashedRaffles({
    int page = 0,
    int pageSize = defaultRafflePageSize,
  }) {
    return _pageOfSummaries(inTrash: true, page: page, pageSize: pageSize);
  }

  Future<Paged<RaffleSummary>> _pageOfSummaries({
    required bool inTrash,
    String? search,
    String? status,
    required int page,
    required int pageSize,
  }) async {
    final total = await raffleLocalDatasource.countRaffles(
      inTrash: inTrash,
      search: search,
      status: status,
    );

    // Si la página quedó fuera de rango (por ejemplo tras borrar la última
    // rifa de la última página) se sirve la última válida.
    final lastPage = pageSize <= 0 ? 0 : ((total / pageSize).ceil() - 1);
    final safePage = page.clamp(0, lastPage < 0 ? 0 : lastPage);

    final rows = await raffleLocalDatasource.getRaffleSummaries(
      inTrash: inTrash,
      search: search,
      status: status,
      limit: pageSize,
      offset: safePage * pageSize,
    );

    return Paged(
      items: rows.map(_toSummary).toList(),
      total: total,
      page: safePage,
      pageSize: pageSize,
    );
  }

  /// Cada fila trae las columnas de la rifa más los contadores del `GROUP BY`.
  RaffleSummary _toSummary(Map<String, dynamic> row) {
    return RaffleSummary(
      raffle: RaffleModel.fromMap(row).toEntity(),
      counts: TicketCounts(
        sold: row['sold_count'] as int,
        reserved: row['reserved_count'] as int,
        available: row['available_count'] as int,
      ),
    );
  }

  @override
  Future<void> createRaffleWithTickets(
      Raffle raffle, List<Ticket> tickets) async {
    await raffleLocalDatasource.insertRaffleWithTickets(
      RaffleModel.fromEntity(raffle),
      tickets.map(TicketModel.fromEntity).toList(),
    );
  }

  @override
  Future<RaffleDetails?> getRaffleDetails(int raffleId) async {
    final row = await raffleLocalDatasource.getRaffleById(raffleId);
    if (row == null) return null;

    final counts = await raffleLocalDatasource.getTicketStatusCounts(raffleId);
    final buyers = await raffleLocalDatasource.getBuyerCounts(raffleId);

    return RaffleDetails(
      raffle: RaffleModel.fromMap(row).toEntity(),
      counts: TicketCounts.fromMap(counts),
      buyers: BuyerCounts(
        total: buyers['total'] ?? 0,
        sold: buyers['sold'] ?? 0,
        reserved: buyers['reserved'] ?? 0,
      ),
    );
  }

  @override
  Future<Paged<Ticket>> getTicketPage(
    int raffleId, {
    int page = 0,
    int pageSize = defaultTicketPageSize,
  }) async {
    final counts = await raffleLocalDatasource.getTicketStatusCounts(raffleId);
    final total = TicketCounts.fromMap(counts).total;

    final lastPage = pageSize <= 0 ? 0 : ((total / pageSize).ceil() - 1);
    final safePage = page.clamp(0, lastPage < 0 ? 0 : lastPage);

    final rows = await raffleLocalDatasource.getTickets(
      raffleId,
      limit: pageSize,
      offset: safePage * pageSize,
    );

    return Paged(
      items: rows.map((row) => TicketModel.fromMap(row).toEntity()).toList(),
      total: total,
      page: safePage,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<Ticket>> getTicketsWithBuyers(int raffleId) async {
    final rows = await raffleLocalDatasource.getTicketsWithBuyers(raffleId);
    return rows.map((row) => TicketModel.fromMap(row).toEntity()).toList();
  }

  @override
  Future<Ticket?> pickRandomAvailableTicket(int raffleId) async {
    final row = await raffleLocalDatasource.pickRandomAvailableTicket(raffleId);
    return row == null ? null : TicketModel.fromMap(row).toEntity();
  }

  @override
  Future<List<Ticket>> getAllTickets(int raffleId) async {
    final rows = await raffleLocalDatasource.getTickets(raffleId);
    return rows.map((row) => TicketModel.fromMap(row).toEntity()).toList();
  }

  @override
  Future<void> updateTicket(Ticket ticket) async {
    final id = ticket.id;
    if (id == null) return;

    await raffleLocalDatasource.updateTicket(
      ticketId: id,
      status: ticket.status,
      buyerName: ticket.buyerName,
      buyerContact: ticket.buyerContact,
    );
  }

  @override
  Future<void> updateRaffle(Raffle raffle) async {
    final raffleId = raffle.id;
    if (raffleId == null) {
      throw ArgumentError('No se puede actualizar una rifa sin id');
    }

    await raffleLocalDatasource.updateRaffle(
      raffleId: raffleId,
      name: raffle.name,
      lotteryNumber: raffle.lotteryNumber,
      priceMinor: raffle.priceMinor,
      date: raffle.date,
      imagePath: raffle.imagePath,
    );
  }

  @override
  Future<void> updateRaffleStatus(int raffleId, String newStatus) =>
      raffleLocalDatasource.updateRaffleStatus(raffleId, newStatus);

  @override
  Future<void> setWinningNumberAndFinishRaffle(
          int raffleId, String winningNumber) =>
      raffleLocalDatasource.setWinningNumberAndFinishRaffle(
          raffleId, winningNumber);

  @override
  Future<void> moveToTrash(int raffleId) =>
      raffleLocalDatasource.moveToTrash(raffleId);

  @override
  Future<void> restoreFromTrash(int raffleId) =>
      raffleLocalDatasource.restoreFromTrash(raffleId);

  @override
  Future<void> deleteForever(int raffleId) =>
      raffleLocalDatasource.deleteForever(raffleId);

  @override
  Future<void> emptyTrash() => raffleLocalDatasource.emptyTrash();

  @override
  Future<int> purgeTrashOlderThan(Duration retention) =>
      raffleLocalDatasource.purgeTrashOlderThan(retention);
}
