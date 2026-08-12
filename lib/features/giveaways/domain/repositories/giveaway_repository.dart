import '../entities/giveaway.dart';

abstract class GiveawayRepository {
  Future<int> createGiveaway({
    required String name,
    required String description,
    required String drawDate,
    required String status,
  });

  Future<void> updateGiveawayStatus({
    required int giveawayId,
    required String newStatus,
  });

  /// Edita nombre, descripción y fecha. El estado va por su propio método.
  Future<void> updateGiveaway({
    required int giveawayId,
    required String name,
    required String description,
    required DateTime drawDate,
  });

  Future<List<Giveaway>> getGiveaways();

  Future<Giveaway?> getGiveaway(int id);

  Future<void> deleteGiveaway(int id);
}
