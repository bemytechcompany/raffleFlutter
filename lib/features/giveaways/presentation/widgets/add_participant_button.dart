import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/participant_bloc.dart';
import '../../../../core/theme/app_colors.dart';

class AddParticipantButton extends StatelessWidget {
  final int giveawayId;

  const AddParticipantButton({super.key, required this.giveawayId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AddParticipantDialog(giveawayId: giveawayId),
        );
      },
      icon: const Icon(Icons.person_add),
      label: const Text('Add Participant'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonGreenBackground,
        foregroundColor: AppColors.buttonGreenForeground,
        side: BorderSide(color: AppColors.buttonGreenBorder),
      ),
    );
  }
}

class AddParticipantDialog extends StatefulWidget {
  final int giveawayId;

  const AddParticipantDialog({super.key, required this.giveawayId});

  @override
  State<AddParticipantDialog> createState() => _AddParticipantDialogState();
}

class _AddParticipantDialogState extends State<AddParticipantDialog> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Participant'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Contact'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final contact = _contactController.text.trim();
            if (name.isNotEmpty && contact.isNotEmpty) {
              context.read<ParticipantBloc>().add(
                    AddParticipantEvent(
                      giveawayId: widget.giveawayId,
                      name: name,
                      contact: contact,
                    ),
                  );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonGreenBackground,
            foregroundColor: AppColors.buttonGreenForeground,
            side: BorderSide(color: AppColors.buttonGreenBorder),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
