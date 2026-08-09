import '../entities/giveaway.dart';
import '../repositories/giveaway_repository.dart';

class GiveawayUseCases {
  final GiveawayRepository repository;

  GiveawayUseCases(this.repository);

  Future<int> createGiveaway({
    required String name,
    required String description,
    required DateTime drawDate,
    required String status,
  }) {
    return repository.createGiveaway(
      name: name,
      description: description,
      drawDate: drawDate.toIso8601String(),
      status: status,
    );
  }

  Future<void> updateGiveawayStatus({
    required int giveawayId,
    required String newStatus,
  }) {
    return repository.updateGiveawayStatus(
      giveawayId: giveawayId,
      newStatus: newStatus,
    );
  }

  Future<void> updateGiveaway({
    required int giveawayId,
    required String name,
    required String description,
    required DateTime drawDate,
  }) {
    return repository.updateGiveaway(
      giveawayId: giveawayId,
      name: name,
      description: description,
      drawDate: drawDate,
    );
  }

  Future<List<Giveaway>> getGiveaways() {
    return repository.getGiveaways();
  }

  Future<Giveaway?> getGiveaway(int id) {
    return repository.getGiveaway(id);
  }

  /// Borra el sorteo. Sus participantes se van con él por la clave foránea
  /// `ON DELETE CASCADE`, no hace falta borrarlos a mano.
  Future<void> deleteGiveaway(int id) {
    return repository.deleteGiveaway(id);
  }
}
