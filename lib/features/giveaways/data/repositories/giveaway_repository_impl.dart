import '../../domain/entities/giveaway.dart';
import '../../domain/repositories/giveaway_repository.dart';
import '../datasources/giveaway_local_datasource.dart';
import '../models/giveaway_model.dart';

class GiveawayRepositoryImpl implements GiveawayRepository {
  final GiveawayLocalDatasource datasource;

  GiveawayRepositoryImpl(this.datasource);

  @override
  Future<int> createGiveaway({
    required String name,
    required String description,
    required String drawDate,
    required String status,
  }) {
    final model = GiveawayModel(
      id: null,
      name: name,
      description: description,
      drawDate: DateTime.parse(drawDate),
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return datasource.insertGiveaway(model);
  }

  @override
  Future<List<Giveaway>> getGiveaways() async {
    final models = await datasource.getAllGiveaways();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Giveaway?> getGiveaway(int id) async {
    final model = await datasource.getGiveawayById(id);
    return model?.toEntity();
  }

  @override
  Future<void> updateGiveawayStatus({
    required int giveawayId,
    required String newStatus,
  }) {
    return datasource.updateGiveawayStatus(giveawayId, newStatus);
  }

  @override
  Future<void> updateGiveaway({
    required int giveawayId,
    required String name,
    required String description,
    required DateTime drawDate,
  }) {
    return datasource.updateGiveaway(
      id: giveawayId,
      name: name,
      description: description,
      drawDate: drawDate,
    );
  }

  @override
  Future<void> deleteGiveaway(int id) {
    return datasource.deleteGiveaway(id);
  }
}
