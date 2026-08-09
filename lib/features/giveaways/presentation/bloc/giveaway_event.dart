part of 'giveaway_bloc.dart';

abstract class GiveawayEvent {}

class LoadGiveaways extends GiveawayEvent {}

class CreateGiveawayEvent extends GiveawayEvent {
  final String name;
  final String description;
  final DateTime drawDate;
  final String status;

  CreateGiveawayEvent({
    required this.name,
    required this.description,
    required this.drawDate,
    required this.status,
  });
}

class UpdateGiveawayStatusEvent extends GiveawayEvent {
  final int giveawayId;
  final String newStatus;

  UpdateGiveawayStatusEvent({
    required this.giveawayId,
    required this.newStatus,
  });
}

class UpdateGiveawayEvent extends GiveawayEvent {
  final int giveawayId;
  final String name;
  final String description;
  final DateTime drawDate;

  UpdateGiveawayEvent({
    required this.giveawayId,
    required this.name,
    required this.description,
    required this.drawDate,
  });
}

class DeleteGiveawayEvent extends GiveawayEvent {
  final int giveawayId;

  DeleteGiveawayEvent(this.giveawayId);
}
