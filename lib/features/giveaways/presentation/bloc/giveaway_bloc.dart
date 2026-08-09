import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/giveaway.dart';
import '../../domain/use_cases/giveaway_use_cases.dart';

part 'giveaway_event.dart';
part 'giveaway_state.dart';

class GiveawayBloc extends Bloc<GiveawayEvent, GiveawayState> {
  final GiveawayUseCases useCases;

  GiveawayBloc(this.useCases) : super(GiveawayInitial()) {
    on<LoadGiveaways>(_onLoadGiveaways);
    on<CreateGiveawayEvent>(_onCreateGiveaway);
    on<UpdateGiveawayStatusEvent>(_onUpdateGiveawayStatus);
    on<UpdateGiveawayEvent>(_onUpdateGiveaway);
    on<DeleteGiveawayEvent>(_onDeleteGiveaway);
  }

  Future<void> _onLoadGiveaways(
    LoadGiveaways event,
    Emitter<GiveawayState> emit,
  ) async {
    emit(GiveawayLoading());
    try {
      final giveaways = await useCases.getGiveaways();
      emit(GiveawayLoaded(giveaways));
    } catch (e) {
      emit(GiveawayError(e.toString()));
    }
  }

  Future<void> _onCreateGiveaway(
    CreateGiveawayEvent event,
    Emitter<GiveawayState> emit,
  ) async {
    try {
      await useCases.createGiveaway(
        name: event.name,
        description: event.description,
        drawDate: event.drawDate,
        status: event.status,
      );
      add(LoadGiveaways());
    } catch (e) {
      emit(GiveawayError(e.toString()));
    }
  }

  Future<void> _onUpdateGiveawayStatus(
    UpdateGiveawayStatusEvent event,
    Emitter<GiveawayState> emit,
  ) async {
    try {
      await useCases.updateGiveawayStatus(
        giveawayId: event.giveawayId,
        newStatus: event.newStatus,
      );
      add(LoadGiveaways());
    } catch (e) {
      emit(GiveawayError(e.toString()));
    }
  }

  Future<void> _onUpdateGiveaway(
    UpdateGiveawayEvent event,
    Emitter<GiveawayState> emit,
  ) async {
    try {
      await useCases.updateGiveaway(
        giveawayId: event.giveawayId,
        name: event.name,
        description: event.description,
        drawDate: event.drawDate,
      );
      add(LoadGiveaways());
    } catch (e) {
      emit(GiveawayError(e.toString()));
    }
  }

  Future<void> _onDeleteGiveaway(
    DeleteGiveawayEvent event,
    Emitter<GiveawayState> emit,
  ) async {
    try {
      await useCases.deleteGiveaway(event.giveawayId);
      add(LoadGiveaways()); // Reload list after deletion
    } catch (e) {
      emit(GiveawayError(e.toString()));
    }
  }
}
