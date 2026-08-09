import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle/features/giveaways/presentation/pages/giveaway_list_page.dart';
import 'package:raffle/features/raffles/presentation/bloc/trash/trash_bloc.dart';
import '../features/raffles/presentation/pages/raffle_list_page.dart';
import '../features/raffles/presentation/pages/trash_page.dart';

/// Una entrada del menú inferior: título, icono y pantalla, juntos.
///
/// Antes eran tres listas paralelas y se habían desincronizado: había cinco
/// pantallas registradas y solo tres botones, así que `HistoryPage` y
/// `SettingsPage` no se podían abrir. Esas dos pantallas siguen en el
/// proyecto, pendientes de enlazar.
class _Destination {
  final String title;
  final IconData icon;
  final Widget page;

  const _Destination({
    required this.title,
    required this.icon,
    required this.page,
  });
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const List<_Destination> _destinations = [
    _Destination(
      title: 'Rifas',
      icon: Icons.confirmation_number,
      page: RaffleListPage(),
    ),
    _Destination(
      title: 'Sorteos',
      icon: Icons.card_giftcard,
      page: GiveawaysListPage(),
    ),
    _Destination(
      title: 'Papelera',
      icon: Icons.delete,
      page: TrashPage(),
    ),
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Mantenimiento de arranque: vacía lo que lleve más de un mes en la
    // papelera para que no crezca sin límite.
    Future.microtask(() {
      if (!mounted) return;
      context.read<TrashBloc>().add(PurgeExpiredTrash());
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(destination.title)),
      body: IndexedStack(
        index: _currentIndex,
        children: [for (final d in _destinations) d.page],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          for (final d in _destinations)
            BottomNavigationBarItem(icon: Icon(d.icon), label: d.title),
        ],
      ),
    );
  }
}
