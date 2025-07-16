import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/keyboard_dismissible.dart';
import '../bloc/giveaway_bloc.dart';

class GiveawayCreatePage extends StatefulWidget {
  const GiveawayCreatePage({super.key});

  @override
  State<GiveawayCreatePage> createState() => _GiveawayCreatePageState();
}

class _GiveawayCreatePageState extends State<GiveawayCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _drawDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<GiveawayBloc>().add(CreateGiveawayEvent(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            drawDate: _drawDate!,
            status: 'pending',
          ));

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎁 Crear Sorteo'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 12,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: KeyboardDismissible(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      'Nuevo Giveaway',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nombre del Sorteo',
                      icon: Icons.card_giftcard,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Descripción',
                      icon: Icons.description,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text('Fecha del sorteo',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.date_range),
                      label: Text(_drawDate == null
                          ? 'Seleccionar fecha'
                          : '${_drawDate!.toLocal()}'.split(' ')[0]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonGreenBackground,
                        foregroundColor: AppColors.buttonGreenForeground,
                        side: BorderSide(color: AppColors.buttonGreenBorder),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('Crear Sorteo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.greenAccent.shade100.withOpacity(0.3),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _drawDate = picked;
      });
    }
  }
}
