import '../../domain/entities/participant.dart';
import '../../domain/repositories/participant_repository.dart';
import '../datasources/participant_local_datasource.dart';
import '../models/participant_model.dart';

class ParticipantRepositoryImpl implements ParticipantRepository {
  final ParticipantLocalDatasource datasource;

  ParticipantRepositoryImpl(this.datasource);

  @override
  Future<int> addParticipant({
    required int giveawayId,
    required String name,
    required String contact,
  }) {
    final now = DateTime.now();
    final participant = ParticipantModel(
      id: null,
      giveawayId: giveawayId,
      name: name,
      contact: contact,
      isPreselected: false,
      isWinner: false,
      createdAt: now,
      updatedAt: now,
    );
    return datasource.insertParticipant(participant);
  }

  @override
  Future<List<Participant>> getParticipants(int giveawayId) async {
    final models = await datasource.getParticipantsByGiveawayId(giveawayId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateParticipant(Participant participant) {
    final model = ParticipantModel.fromEntity(participant);
    return datasource.updateParticipant(model);
  }

  @override
  Future<void> deleteParticipant(int id) {
    return datasource.deleteParticipant(id);
  }

  @override
  Future<void> deleteParticipantsByGiveaway(int giveawayId) {
    return datasource.deleteParticipantsByGiveaway(giveawayId);
  }

  @override
  Future<void> preselectParticipants({
    required int giveawayId,
    required int count,
  }) {
    return datasource.preselectParticipants(
      giveawayId: giveawayId,
      count: count,
    );
  }

  @override
  Future<Participant?> drawWinner(int giveawayId) {
    return datasource.drawWinner(giveawayId);
  }

  @override
  Future<void> resetDraw(int giveawayId) {
    return datasource.resetDraw(giveawayId);
  }
}
