import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle/features/raffles/data/datasources/raffle_local_datasource.dart';
import 'package:raffle/features/raffles/data/datasources/ticket_dao.dart';
import 'package:raffle/features/raffles/data/repositories/raffle_repository_impl.dart';
import 'package:raffle/features/raffles/domain/repositories/raffle_repository.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/details/raffle_details_bloc.dart';
import 'package:raffle/features/giveaways/presentation/bloc/giveaway_bloc.dart';
import 'package:raffle/features/giveaways/presentation/bloc/participant_bloc.dart';
import 'package:raffle/features/giveaways/data/repositories/giveaway_repository_impl.dart';
import 'package:raffle/features/giveaways/data/repositories/participant_repository_impl.dart';
import 'package:raffle/features/giveaways/data/datasources/giveaway_local_datasource.dart';
import 'package:raffle/features/giveaways/data/datasources/participant_local_datasource.dart';

import 'features/giveaways/domain/use_cases/giveaway_use_cases.dart';
import 'features/giveaways/domain/use_cases/participant_usecases.dart';
import 'layout/main_layout.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  final RaffleRepository raffleRepository = RaffleRepositoryImpl(
    raffleLocalDatasource: RaffleLocalDatasource.instance,
    ticketDao: TicketDao.instance,
  );

  final giveawayRepository =
      GiveawayRepositoryImpl(GiveawayLocalDatasource.instance);
  final participantRepository =
      ParticipantRepositoryImpl(ParticipantLocalDatasource.instance);

  final giveawayUseCases = GiveawayUseCases(giveawayRepository);
  final participantUseCases = ParticipantUseCases(participantRepository);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RaffleBloc(raffleRepository)),
        BlocProvider(create: (_) => RaffleDetailsBloc(raffleRepository)),
        BlocProvider(create: (_) => GiveawayBloc(giveawayUseCases)),
        BlocProvider(create: (_) => ParticipantBloc(participantUseCases)),
      ],
      child: const MyApp(),
    ),
  );
}

// Crear un widget global para manejar el teclado
class GlobalKeyboardDismissWrapper extends StatelessWidget {
  final Widget child;

  const GlobalKeyboardDismissWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Cerrar teclado en iOS y Android
        FocusScope.of(context).unfocus();
        // Forzar cierre específico para iOS
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raffle App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('es'), // Fuerza español
      supportedLocales: const [
        Locale('es'), // Solo español en este caso
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Agregar el wrapper global aquí
      builder: (context, child) {
        return GlobalKeyboardDismissWrapper(child: child ?? Container());
      },
      home: const MainLayout(),
    );
  }
}
