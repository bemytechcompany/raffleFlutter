import 'package:flutter/material.dart';
import 'package:raffle/features/giveaways/presentation/pages/giveaway_list_page.dart';
import '../core/theme/app_colors.dart';
import '../features/raffles/presentation/pages/raffle_list_page.dart';
import '../features/raffles/presentation/pages/trash_page.dart';
import '../features/raffles/presentation/pages/history_page.dart';
import '../features/raffles/presentation/pages/settings_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    RaffleListPage(),
    GiveawaysListPage(),
    TrashPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  final List<String> _titles = [
    'Rifas',
    'Sorteos',
    'Papelera',
    'History',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: "Rifas"),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: "Sorteos"),
          BottomNavigationBarItem(icon: Icon(Icons.delete), label: "Papelera"),
          //BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          //BottomNavigationBarItem(
          //icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
