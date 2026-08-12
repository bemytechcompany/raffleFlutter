import 'package:raffle/core/pagination/paged.dart';

import '../entities/raffle.dart';
import '../entities/raffle_details.dart';
import '../entities/raffle_summary.dart';
import '../entities/ticket.dart';

abstract class RaffleRepository {
  /// Página de rifas activas con sus contadores, filtradas en SQL.
  ///
  /// [search] busca en el nombre y en el de la lotería; [status] admite
  /// `'all'` o uno de los estados de la rifa.
  Future<Paged<RaffleSummary>> getRaffleSummaries({
    String? search,
    String? status,
    int page,
    int pageSize,
  });

  /// Página de rifas que están en la papelera.
  Future<Paged<RaffleSummary>> getTrashedRaffles({
    int page,
    int pageSize,
  });

  Future<void> createRaffleWithTickets(Raffle raffle, List<Ticket> tickets);

  /// Cabecera del detalle: la rifa y sus contadores, sin boletos.
  Future<RaffleDetails?> getRaffleDetails(int raffleId);

  /// Una página de boletos de la rifa, ordenados por número.
  Future<Paged<Ticket>> getTicketPage(
    int raffleId, {
    int page,
    int pageSize,
  });

  /// Solo los boletos que tienen comprador.
  Future<List<Ticket>> getTicketsWithBuyers(int raffleId);

  /// El boleto ganador, sorteado por la base entre todos los de la rifa y no
  /// solo entre los de la página cargada.
  ///
  /// Si hay boletos vendidos el ganador sale de ellos; si aún no se ha vendido
  /// ninguno, entran todos.
  Future<Ticket?> pickWinningTicket(int raffleId);

  /// Todos los boletos de la rifa. Lo usan compartir y exportar, que necesitan
  /// la lista completa; el resto de pantallas debe paginar.
  Future<List<Ticket>> getAllTickets(int raffleId);

  Future<void> updateTicket(Ticket ticket);
  Future<void> updateRaffle(Raffle raffle);
  Future<void> updateRaffleStatus(int raffleId, String newStatus);
  Future<void> setWinningNumberAndFinishRaffle(
      int raffleId, String winningNumber);

  /// Deshace el sorteo: borra el número ganador y devuelve la rifa a `active`.
  Future<void> resetDraw(int raffleId);

  /// Envía la rifa a la papelera; se puede restaurar.
  Future<void> moveToTrash(int raffleId);
  Future<void> restoreFromTrash(int raffleId);

  /// Borrado definitivo: la rifa y sus boletos desaparecen.
  Future<void> deleteForever(int raffleId);
  Future<void> emptyTrash();

  /// Elimina lo que lleve más de [retention] en la papelera y devuelve cuántas
  /// rifas se borraron.
  Future<int> purgeTrashOlderThan(Duration retention);
}
