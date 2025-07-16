import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/raffle_repository.dart';
import '../../../data/models/raffle_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/datasources/raffle_local_datasource.dart';
import 'raffle_details_event.dart';
import 'raffle_details_state.dart';

class RaffleDetailsBloc extends Bloc<RaffleDetailsEvent, RaffleDetailsState> {
  final RaffleRepository repository;
  final RaffleLocalDatasource localDatasource = RaffleLocalDatasource.instance;

  RaffleDetailsBloc(this.repository) : super(RaffleDetailsInitial()) {
    on<LoadRaffleDetails>((event, emit) async {
      emit(RaffleDetailsLoading());
      try {
        final result = await repository.getRaffleWithTickets(event.raffleId);
        if (result == null) {
          emit(const RaffleDetailsError('Raffle not found.'));
          return;
        }

        final raffleMap = Map<String, dynamic>.from(result['raffle']);

        final ticketsList = List<Map<String, dynamic>>.from(result['tickets']);

        final raffle = RaffleModel.fromMap(raffleMap).toEntity();

        final tickets = ticketsList.map((t) {
          final model = TicketModel.fromMap(t);
          return model.toEntity();
        }).toList();

        emit(RaffleDetailsLoaded(raffle: raffle, tickets: tickets));
      } catch (e, stack) {
        print("❌ ERROR: $e");
        print("📍 STACK TRACE:\n$stack");
        emit(RaffleDetailsError(e.toString()));
      }
    });

    on<ChangeRaffleStatus>((event, emit) async {
      try {
        await repository.updateRaffleStatus(event.raffleId, event.newStatus);
        add(LoadRaffleDetails(event.raffleId));
      } catch (e) {
        emit(RaffleDetailsError(e.toString()));
      }
    });

    on<EditTicket>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is RaffleDetailsLoaded) {
          final raffleId = currentState.raffle.id;
          if (raffleId == null) {
            emit(const RaffleDetailsError('Invalid raffle ID.'));
            return;
          }

          // Actualizar el ticket
          await repository.updateTicket(event.ticket);

          // Recargar los datos
          final result = await repository.getRaffleWithTickets(raffleId);
          if (result == null) {
            emit(const RaffleDetailsError('Raffle not found after update.'));
            return;
          }

          final raffleMap = Map<String, dynamic>.from(result['raffle']);
          final ticketsList =
              List<Map<String, dynamic>>.from(result['tickets']);

          final raffle = RaffleModel.fromMap(raffleMap).toEntity();
          final tickets = ticketsList.map((t) {
            final ticket = TicketModel.fromMap(t).toEntity();
            return ticket;
          }).toList();

          emit(RaffleDetailsLoaded(raffle: raffle, tickets: tickets));
        }
      } catch (e, stack) {
        print("❌ Error al actualizar ticket: $e");
        print("📍 Stack trace:\n$stack");
        emit(RaffleDetailsError(e.toString()));
      }
    });

    on<DeleteRaffle>((event, emit) async {
      try {
        await repository.deleteRaffleAndTickets(event.raffleId);
        emit(RaffleDetailsInitial());
      } catch (e) {
        print("hola 3");

        emit(RaffleDetailsError(e.toString()));
      }
    });

    on<SetWinningNumber>((event, emit) async {
      try {
        // Usar el nuevo método que actualiza el número ganador y finaliza la rifa si es tipo 'app'
        await repository.setWinningNumberAndFinishRaffle(
            event.raffleId, event.winningNumber);
        add(LoadRaffleDetails(event.raffleId));
      } catch (e) {
        emit(RaffleDetailsError(e.toString()));
      }
    });
  }
}
