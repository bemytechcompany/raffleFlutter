import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/participant.dart';
import '../../domain/use_cases/participant_usecases.dart';

part 'participant_event.dart';
part 'participant_state.dart';

class ParticipantBloc extends Bloc<ParticipantEvent, ParticipantState> {
  final ParticipantUseCases useCases;

  ParticipantBloc(this.useCases) : super(ParticipantInitial()) {
    on<LoadParticipants>(_onLoadParticipants);
    on<AddParticipantEvent>(_onAddParticipant);
    on<UpdateParticipantEvent>(_onUpdateParticipant);
    on<DeleteParticipantEvent>(_onDeleteParticipant);
    on<DeleteParticipantsByGiveawayEvent>(_onDeleteParticipantsByGiveaway);
    on<PreselectParticipantsEvent>(_onPreselectParticipants);
    on<DrawWinnerEvent>(_onDrawWinner);
  }

  Future<void> _onLoadParticipants(
    LoadParticipants event,
    Emitter<ParticipantState> emit,
  ) async {
    emit(ParticipantLoading());
    try {
      final participants = await useCases.getParticipants(event.giveawayId);
      emit(ParticipantLoaded(participants));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onAddParticipant(
    AddParticipantEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      await useCases.addParticipant(
        giveawayId: event.giveawayId,
        name: event.name,
        contact: event.contact,
      );
      emit(ParticipantLoading()); // fuerza cambio de estado
      final participants = await useCases.getParticipants(event.giveawayId);
      emit(ParticipantLoaded(participants));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onUpdateParticipant(
    UpdateParticipantEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      await useCases.updateParticipant(event.participant);
      add(LoadParticipants(giveawayId: event.participant.giveawayId));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onDeleteParticipant(
    DeleteParticipantEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      await useCases.deleteParticipant(event.participantId);
      add(LoadParticipants(giveawayId: event.giveawayId));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onDeleteParticipantsByGiveaway(
    DeleteParticipantsByGiveawayEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      await useCases.deleteParticipantsByGiveaway(event.giveawayId);
      add(LoadParticipants(giveawayId: event.giveawayId));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onPreselectParticipants(
    PreselectParticipantsEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      await useCases.preselectParticipants(
        giveawayId: event.giveawayId,
        count: event.count,
      );

      add(LoadParticipants(giveawayId: event.giveawayId));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onDrawWinner(
    DrawWinnerEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      final winner = await useCases.drawWinner(event.giveawayId);

      if (winner == null) {
        emit(const ParticipantError(
            'No hay participantes disponibles para sortear.'));
        return;
      }

      // Se emite un único estado con el ganador y la lista ya actualizada, en
      // vez de emitir el ganador y encadenar una recarga que lo reemplazaba.
      final participants = await useCases.getParticipants(event.giveawayId);
      emit(WinnerSelected(winner, participants));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }
}
