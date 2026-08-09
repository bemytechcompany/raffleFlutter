import 'package:flutter/material.dart';
import '../../domain/entities/giveaway.dart';
import '../../../../core/theme/app_colors.dart';

class GiveawayCard extends StatelessWidget {
  final Giveaway giveaway;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GiveawayCard({
    super.key,
    required this.giveaway,
    required this.onTap,
    required this.onDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          giveaway.name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            giveaway.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(giveaway.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _translateStatus(giveaway.status),
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            // Mismo sitio que en las rifas: el menú de la tarjeta. Borrar era
            // lo único que la pantalla no dejaba hacer con un sorteo.
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              tooltip: 'Opciones del sorteo',
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      case 'pending':
      default:
        return 'Pendiente';
    }
  }
}
