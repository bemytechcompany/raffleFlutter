import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/keyboard_dismissible.dart';

class RaffleEditPage extends StatefulWidget {
  final Raffle raffle;

  const RaffleEditPage({
    super.key,
    required this.raffle,
  });

  @override
  State<RaffleEditPage> createState() => _RaffleEditPageState();
}

class _RaffleEditPageState extends State<RaffleEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lotteryNumberController;
  late TextEditingController _priceController;
  late DateTime _drawDate;
  File? _selectedImage;
  late String _gameType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.raffle.name);
    _lotteryNumberController = TextEditingController(text: widget.raffle.lotteryNumber);
    _priceController = TextEditingController(text: widget.raffle.price.toString());
    _drawDate = widget.raffle.date;
    _gameType = widget.raffle.gameType;
    if (widget.raffle.imagePath != null) {
      _selectedImage = File(widget.raffle.imagePath!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lotteryNumberController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RaffleBloc>().add(
            UpdateRaffle(
              raffleId: widget.raffle.id!,
              name: _nameController.text.trim(),
              lotteryNumber: _gameType == 'lottery' ? _lotteryNumberController.text.trim() : '',
              price: double.parse(_priceController.text.trim()),
              drawDate: _drawDate,
              imagePath: _selectedImage?.path,
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✏️ Editar Rifa'),
        centerTitle: true,
        elevation: 2,
      ),
      body: KeyboardDismissible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? const Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.white54,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Información del tipo de rifa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _gameType == 'lottery' ? Icons.confirmation_number : Icons.casino,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tipo de Rifa: ${_gameType == 'lottery' ? 'Lotería Nacional' : 'Sorteo en la App'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Rifa',
                    prefixIcon: Icon(Icons.edit),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_gameType == 'lottery') ...[
                  TextFormField(
                    controller: _lotteryNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Lotería',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Por favor ingresa el nombre de lotería';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio por Ticket',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor ingresa el precio';
                    }
                    final price = double.tryParse(value!);
                    if (price == null || price <= 0) {
                      return 'Por favor ingresa un precio válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Fecha del Sorteo'),
                  subtitle: Text(
                    '${_drawDate.day}/${_drawDate.month}/${_drawDate.year}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _drawDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _drawDate = date);
                    }
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonGreenBackground,
                    foregroundColor: AppColors.buttonGreenForeground,
                    side: BorderSide(color: AppColors.buttonGreenBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 