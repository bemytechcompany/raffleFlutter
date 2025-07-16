import 'package:flutter/material.dart';
import 'package:raffle/core/theme/app_colors.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';

class BuyersSummary extends StatelessWidget {
  final List<Ticket> tickets;
  final VoidCallback onTap;

  const BuyersSummary({
    super.key,
    required this.tickets,
    required this.onTap,
  });

  Map<String, int> _getBuyersCount() {
    int total = 0;
    int sold = 0;
    int reserved = 0;

    for (var ticket in tickets) {
      if (ticket.buyerName != null) {
        total++;
        if (ticket.status == 'sold') {
          sold++;
        } else if (ticket.status == 'reserved') {
          reserved++;
        }
      }
    }

    return {
      'total': total,
      'sold': sold,
      'reserved': reserved,
    };
  }

  @override
  Widget build(BuildContext context) {
    final buyersCount = _getBuyersCount();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Compradores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ver lista',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.buttonGreenForeground,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.list_alt,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CounterItem(
                    label: 'Total',
                    count: buyersCount['total']!,
                    color: Colors.blue,
                  ),
                  _CounterItem(
                    label: 'Vendidas',
                    count: buyersCount['sold']!,
                    color: Colors.green,
                  ),
                  _CounterItem(
                    label: 'Reservadas',
                    count: buyersCount['reserved']!,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CounterItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
