import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:raffle/features/raffles/domain/repositories/raffle_repository.dart';

import 'raffle_event.dart';
import 'raffle_state.dart';

class RaffleBloc extends Bloc<RaffleEvent, RaffleState> {
  final RaffleRepository repository;

  RaffleBloc(this.repository) : super(RaffleLoading()) {
    on<LoadRaffles>((event, emit) async {
      emit(RaffleLoading());
      try {
        final raffles = await repository.getAllRaffles();
        emit(RaffleLoaded(raffles: raffles));
      } catch (e) {
        emit(RaffleError(message: e.toString()));
      }
    });

    on<CreateRaffle>((event, emit) async {
      try {
        final newRaffle = Raffle(
          id: null,
          name: event.name,
          lotteryNumber: event.lotteryNumber,
          price: event.price,
          totalTickets: event.totalTickets,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          date: event.drawDate,
          imagePath: event.imagePath,
          gameType: event.gameType,
          digitCount: event.digitCount,
        );

        // Generar tickets según el tipo de juego
        final tickets = List.generate(event.totalTickets, (i) {
          String number;
          if (event.gameType == 'lottery') {
            // Para lotería, formatea el número con ceros a la izquierda
            number = i.toString().padLeft(event.digitCount, '0');
          } else {
            // Para sorteo en app, usa números secuenciales
            number = (i + 1).toString();
          }
          
          return Ticket(
            id: null,
            raffleId: 0, // se asignará luego en el repo
            number: int.parse(number),
            status: 'available',
          );
        });

        await repository.createRaffleWithTickets(newRaffle, tickets);
        add(LoadRaffles());
      } catch (e) {
        emit(RaffleError(message: e.toString()));
      }
    });

    on<DeleteRaffle>((event, emit) async {
      try {
        await repository.deleteRaffleAndTickets(event.raffleId);
        add(LoadRaffles());
      } catch (e) {
        emit(RaffleError(message: e.toString()));
      }
    });

    on<UpdateRaffleStatusEvent>((event, emit) async {
      try {
        await repository.updateRaffleStatus(event.raffleId, event.newStatus);
        add(LoadRaffles());
      } catch (e) {
        emit(RaffleError(message: e.toString()));
      }
    });

    on<UpdateRaffle>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is RaffleLoaded) {
          final raffle = currentState.raffles.firstWhere((r) => r.id == event.raffleId);
          
          final updatedRaffle = raffle.copyWith(
            name: event.name,
            lotteryNumber: event.lotteryNumber,
            price: event.price,
            date: event.drawDate,
            imagePath: event.imagePath,
            updatedAt: DateTime.now(),
          );

          await repository.updateRaffle(updatedRaffle);
          add(LoadRaffles());
        }
      } catch (e) {
        emit(RaffleError(message: e.toString()));
      }
    });

    on<UpdateTicketEvent>((event, emit) async {
      try {
        await repository.updateTicket(event.ticket);
        add(LoadRaffles());
      } catch (e) {
        emit(RaffleError(message: e.toString()));
      }
    });
  }
}
