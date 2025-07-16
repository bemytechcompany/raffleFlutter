import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_bloc.dart';
import 'package:raffle/features/raffles/presentation/bloc/raffle_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/keyboard_dismissible.dart';
import 'dart:math';

class RaffleCreatePage extends StatefulWidget {
  const RaffleCreatePage({super.key});

  @override
  State<RaffleCreatePage> createState() => _RaffleCreatePageState();
}

class _RaffleCreatePageState extends State<RaffleCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lotteryNumberController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalTicketsController = TextEditingController();

  DateTime? _drawDate;
  File? _selectedImage;
  String _gameType = 'app';
  int _digitCount = 2;

  @override
  void dispose() {
    _nameController.dispose();
    _lotteryNumberController.dispose();
    _priceController.dispose();
    _totalTicketsController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissible(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Crear Nueva Rifa',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.primary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen de la rifa
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 50 ,color: AppColors.background,),
                                SizedBox(height: 8),
                                Text('Toca para agregar una imagen', style: TextStyle(color: AppColors.textBlack)),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nombre de la rifa
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información básica',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de la Rifa',
                            prefixIcon: const Icon(Icons.edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Precio por Boleto',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un precio';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Por favor ingresa un número válido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Configuración del sorteo
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configuración del sorteo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _gameType,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Sorteo',
                            prefixIcon: const Icon(Icons.casino),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'app',
                              child: Text('Sorteo en la App'),
                            ),
                            DropdownMenuItem(
                              value: 'lottery',
                              child: Text('Lotería Nacional'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _gameType = value!;
                              if (_gameType == 'lottery') {
                                _totalTicketsController.text =
                                    (pow(10, _digitCount) as int).toString();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_gameType == 'lottery') ...[
                          DropdownButtonFormField<int>(
                            value: _digitCount,
                            decoration: InputDecoration(
                              labelText: 'Número de Dígitos',
                              prefixIcon: const Icon(Icons.format_list_numbered),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 2,
                                child: Text('2 dígitos (00-99)'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('3 dígitos (000-999)'),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text('4 dígitos (0000-9999)'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _digitCount = value!;
                                _totalTicketsController.text =
                                    (pow(10, _digitCount) as int).toString();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lotteryNumberController,
                            decoration: InputDecoration(
                              labelText: 'Nombre de la loteria',
                              prefixIcon: const Icon(Icons.confirmation_number),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa el nombre de la loteria';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _totalTicketsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Total de Boletos',
                              prefixIcon: const Icon(Icons.confirmation_number),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa el total de boletos';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Por favor ingresa un número válido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Fecha del sorteo
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      _drawDate == null
                          ? 'Seleccionar Fecha del Sorteo'
                          : 'Fecha: ${_drawDate!.day}/${_drawDate!.month}/${_drawDate!.year}',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _drawDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _drawDate = date);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Botón de crear
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _drawDate != null) {
                      context.read<RaffleBloc>().add(
                            CreateRaffle(
                              name: _nameController.text,
                              lotteryNumber: _lotteryNumberController.text,
                              price: double.parse(_priceController.text),
                              totalTickets:
                                  int.parse(_totalTicketsController.text),
                              drawDate: _drawDate!,
                              imagePath: _selectedImage?.path,
                              gameType: _gameType,
                              digitCount: _digitCount,
                            ),
                          );
                      Navigator.pop(context);
                    } else if (_drawDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor selecciona una fecha'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonGreenBackground,
                    foregroundColor: AppColors.buttonGreenForeground,
                    side: BorderSide(color: AppColors.buttonGreenBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Crear Rifa',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
