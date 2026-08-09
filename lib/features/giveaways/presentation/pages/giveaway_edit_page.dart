import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/keyboard_dismissible.dart';
import '../../domain/entities/giveaway.dart';
import '../bloc/giveaway_bloc.dart';

/// Edición de un sorteo ya creado.
///
/// Solo toca nombre, descripción y fecha. El estado se cambia desde el detalle
/// y además lo mueve el propio sorteo al elegir ganador, así que meterlo aquí
/// haría que guardar sin darse cuenta reabriera un sorteo ya resuelto.
class GiveawayEditPage extends StatefulWidget {
  final Giveaway giveaway;

  const GiveawayEditPage({super.key, required this.giveaway});

  @override
  State<GiveawayEditPage> createState() => _GiveawayEditPageState();
}

class _GiveawayEditPageState extends State<GiveawayEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late DateTime _drawDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.giveaway.name);
    _descriptionCtrl = TextEditingController(text: widget.giveaway.description);
    _drawDate = widget.giveaway.drawDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _drawDate,
      // Se permite retroceder: al corregir un sorteo viejo la fecha original
      // puede ser anterior a hoy, y bloquearla obligaría a inventarse otra.
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _drawDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<GiveawayBloc>().add(
          UpdateGiveawayEvent(
            giveawayId: widget.giveaway.id!,
            name: _nameCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            drawDate: _drawDate,
          ),
        );

    // Se devuelve el sorteo ya actualizado para que el detalle repinte la
    // cabecera sin esperar a que vuelva la recarga del listado.
    Navigator.of(context).pop(
      Giveaway(
        id: widget.giveaway.id,
        name: _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        drawDate: _drawDate,
        status: widget.giveaway.status,
        createdAt: widget.giveaway.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Editar Sorteo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: KeyboardDismissible(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: _decoration('Nombre', Icons.card_giftcard),
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: _decoration('Descripción', Icons.notes),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade800),
                ),
                leading: const Icon(Icons.event, color: AppColors.primary),
                title: const Text('Fecha del sorteo'),
                subtitle: Text(
                  '${_drawDate.day.toString().padLeft(2, '0')}/'
                  '${_drawDate.month.toString().padLeft(2, '0')}/'
                  '${_drawDate.year}',
                ),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickDate,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonGreenBackground,
                  foregroundColor: AppColors.buttonGreenForeground,
                  side: const BorderSide(color: AppColors.buttonGreenBorder),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
