import 'package:flutter/material.dart';
import '../../domain/entities/giveaway.dart';
import '../pages/giveaway_details_page.dart';
import '../../../../core/theme/app_colors.dart';

class GiveawayListWidget extends StatelessWidget {
  final List<Giveaway> giveaways;

  const GiveawayListWidget({super.key, required this.giveaways});

  @override
  Widget build(BuildContext context) {
    if (giveaways.isEmpty) {
      return const Center(child: Text('No giveaways created.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: giveaways.length,
      itemBuilder: (context, index) {
        final giveaway = giveaways[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: ListTile(
            title: Text(giveaway.name),
            subtitle: Text(
                'Draw Date: ${giveaway.drawDate.toLocal().toString().split(' ')[0]}'),
            trailing: Text(
              giveaway.status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(giveaway.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GiveawayDetailsPage(giveaway: giveaway),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.giveawayCompleted;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
