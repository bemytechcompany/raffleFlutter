import '../entities/raffle.dart';
import '../entities/ticket.dart';

abstract class RaffleRepository {
  Future<void> createRaffle(Raffle raffle);
  Future<void> createRaffleWithTickets(Raffle raffle, List<Ticket> tickets);
  Future<List<Raffle>> getAllRaffles();
  Future<Map<String, dynamic>?> getRaffleWithTickets(int raffleId);
  Future<void> updateTicket(Ticket ticket);
  Future<void> updateRaffleStatus(int raffleId, String newStatus);
  Future<void> deleteRaffleAndTickets(int raffleId);
  Future<void> updateRaffle(Raffle raffle);
  Future<void> setWinningNumberAndFinishRaffle(int raffleId, String winningNumber);
}
