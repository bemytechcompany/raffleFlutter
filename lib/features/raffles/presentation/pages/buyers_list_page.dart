import 'package:flutter/material.dart';
import 'package:raffle/core/theme/app_colors.dart';
import 'package:raffle/core/theme/button_styles.dart';
import 'package:raffle/features/raffles/domain/entities/raffle.dart';
import 'package:raffle/features/raffles/domain/entities/ticket.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class BuyersListPage extends StatefulWidget {
  final Raffle raffle;
  final List<Ticket> tickets;

  const BuyersListPage({
    super.key,
    required this.raffle,
    required this.tickets,
  });

  @override
  State<BuyersListPage> createState() => _BuyersListPageState();
}

class _BuyersListPageState extends State<BuyersListPage> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _searchFilter = 'all'; // 'all', 'number', 'name', 'contact'
  List<Ticket> _filteredTickets = [];
  List<Ticket> _paginatedTickets = [];
  int _currentPage = 1;
  final int _itemsPerPage = 100;

  @override
  void initState() {
    super.initState();
    _filterTickets();
  }

  void _filterTickets() {
    _filteredTickets = widget.tickets.where((ticket) {
      if (ticket.buyerName == null) return false;

      final searchLower = _searchQuery.toLowerCase();
      bool matchesSearch = false;

      if (_searchQuery.isEmpty) {
        matchesSearch = true;
      } else {
        switch (_searchFilter) {
          case 'all':
            matchesSearch = ticket.number.toString().contains(_searchQuery) ||
                ticket.buyerName!.toLowerCase().contains(searchLower) ||
                ticket.buyerContact!.toLowerCase().contains(searchLower);
            break;
          case 'number':
            matchesSearch = ticket.number.toString().contains(_searchQuery);
            break;
          case 'name':
            matchesSearch =
                ticket.buyerName!.toLowerCase().contains(searchLower);
            break;
          case 'contact':
            matchesSearch =
                ticket.buyerContact!.toLowerCase().contains(searchLower);
            break;
        }
      }

      final matchesStatus =
          _statusFilter == 'all' || ticket.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    // Reset to first page when filtering changes
    _currentPage = 1;
    _updatePaginatedTickets();
  }

  void _updatePaginatedTickets() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    _paginatedTickets = _filteredTickets.sublist(
      startIndex,
      endIndex > _filteredTickets.length ? _filteredTickets.length : endIndex,
    );
  }

  int get _totalPages => (_filteredTickets.length / _itemsPerPage).ceil();

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
      _updatePaginatedTickets();
    });
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;

              return Column(
                children: [
                  // Indicador de página actual
                  Text(
                    'Página $_currentPage de $_totalPages',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Controles de navegación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isSmallScreen)
                        IconButton(
                          onPressed:
                              _currentPage > 1 ? () => _goToPage(1) : null,
                          icon: const Icon(Icons.first_page),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      IconButton(
                        onPressed: _currentPage > 1
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      // Selector de página
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen ? 200 : 300,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _currentPage - 1,
                            isDense: true,
                            isExpanded: true,
                            items: List.generate(_totalPages, (index) {
                              final start = index * _itemsPerPage + 1;
                              final end = (index + 1) * _itemsPerPage >
                                      _filteredTickets.length
                                  ? _filteredTickets.length
                                  : (index + 1) * _itemsPerPage;
                              return DropdownMenuItem(
                                value: index,
                                child: Text(
                                  'Compradores $start-$end',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                _goToPage(value + 1);
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _currentPage < _totalPages
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      if (!isSmallScreen)
                        IconButton(
                          onPressed: _currentPage < _totalPages
                              ? () => _goToPage(_totalPages)
                              : null,
                          icon: const Icon(Icons.last_page),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('dd-MM-yyyy_HH-mm');
    return formatter.format(now);
  }

  String _getStatusInSpanish(String status) {
    switch (status) {
      case 'sold':
        return 'Vendido';
      case 'reserved':
        return 'Reservado';
      default:
        return status;
    }
  }

  String _getSearchHint() {
    switch (_searchFilter) {
      case 'number':
        return 'Buscar por número';
      case 'name':
        return 'Buscar por nombre';
      case 'contact':
        return 'Buscar por contacto';
      default:
        return 'Buscar por número, nombre o contacto';
    }
  }

  Future<String> _getExportPath(String extension) async {
    final timestamp = _getFormattedDate();
    final fileName = 'compradores_${widget.raffle.name}_$timestamp.$extension'
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/$fileName';
    } else {
      final directory = await getTemporaryDirectory();
      return '${directory.path}/$fileName';
    }
  }

  Future<void> _exportToPdf() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Lista de Compradores',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          widget.raffle.name,
                          style: const pw.TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Fecha: ${_getFormattedDate()}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Total boletas: ${_filteredTickets.length}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Table.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.black),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    headerHeight: 25,
                    cellHeight: 40,
                    cellAlignments: {
                      0: pw.Alignment.center,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerLeft,
                      3: pw.Alignment.center,
                    },
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    cellStyle: const pw.TextStyle(
                      fontSize: 10,
                    ),
                    headers: ['Número', 'Nombre', 'Contacto', 'Estado'],
                    data: _filteredTickets
                        .map((ticket) => [
                              ticket.number.toString(),
                              ticket.buyerName ?? '',
                              ticket.buyerContact ?? '',
                              _getStatusInSpanish(ticket.status),
                            ])
                        .toList(),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Resumen:',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Vendidas: ${_filteredTickets.where((t) => t.status == 'sold').length}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Reservadas: ${_filteredTickets.where((t) => t.status == 'reserved').length}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Valor total: \$${(widget.raffle.price * _filteredTickets.where((t) => t.status == 'sold').length).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final filePath = await _getExportPath('pdf');
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Lista de Compradores - ${widget.raffle.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar PDF: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = Excel.createExcel();

      // Crear la hoja de compradores
      final sheet = excel['Compradores'];

      // Encabezados
      final headers = ['Número', 'Nombre', 'Contacto', 'Estado'];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // Datos
      for (var i = 0; i < _filteredTickets.length; i++) {
        final ticket = _filteredTickets[i];
        final rowIndex = i + 1;

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = IntCellValue(ticket.number);

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(ticket.buyerName ?? '');

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(ticket.buyerContact ?? '');

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(_getStatusInSpanish(ticket.status));
      }

      // Ajustar ancho de columnas
      sheet.setColumnWidth(0, 15);
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 30);
      sheet.setColumnWidth(3, 20);

      // Remover la hoja por defecto si existe
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }
      final filePath = await _getExportPath('xlsx');
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Lista de Compradores - ${widget.raffle.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar Excel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        foregroundColor: AppColors.text,
        title: const Text('Lista de Compradores'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            onSelected: (value) {
              if (value == 'pdf') {
                _exportToPdf();
              } else if (value == 'excel') {
                _exportToExcel();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Text('Exportar PDF'),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Text('Exportar Excel'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        style: TextStyle(color: AppColors.text),
                        decoration: InputDecoration(
                          hintText: _getSearchHint(),
                          hintStyle: TextStyle(color: AppColors.textHint),
                          prefixIcon: Icon(Icons.search, color: AppColors.text),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundInput,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _filterTickets();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundInput,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _searchFilter,
                            isExpanded: true,
                            style: TextStyle(color: AppColors.text),
                            dropdownColor: AppColors.backgroundModal,
                            onChanged: (String? newValue) {
                              setState(() {
                                _searchFilter = newValue!;
                                _filterTickets();
                              });
                            },
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Todo', style: TextStyle(color: AppColors.text)),
                              ),
                              DropdownMenuItem(
                                value: 'number',
                                child: Text('Número', style: TextStyle(color: AppColors.text)),
                              ),
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('Nombre', style: TextStyle(color: AppColors.text)),
                              ),
                              DropdownMenuItem(
                                value: 'contact',
                                child: Text('Contacto', style: TextStyle(color: AppColors.text)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AppColors.backgroundCard,
                    foregroundColor: AppColors.text,
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: AppColors.text, // Texto blanco cuando está seleccionado
                    side: BorderSide(color: AppColors.border),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'all',
                      label: Text('Todos'),
                    ),
                    ButtonSegment(
                      value: 'sold',
                      label: Text('Vendidos'),
                    ),
                    ButtonSegment(
                      value: 'reserved',
                      label: Text('Reservados'),
                    ),
                  ],
                  selected: {_statusFilter},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _statusFilter = newSelection.first;
                      _filterTickets();
                    });
                  },
                ),
              ],
            ),
          ),
          // Controles de paginación
          if (_filteredTickets.isNotEmpty && _totalPages > 1)
            _buildPagination(),
          Expanded(
            child: ListView.builder(
              itemCount: _paginatedTickets.length,
              itemBuilder: (context, index) {
                final ticket = _paginatedTickets[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.text,
                    child: Text(
                      ticket.number.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text, // Números en blanco
                      ),
                    ),
                  ),
                  title: Text(
                    ticket.buyerName ?? '',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    ticket.buyerContact ?? '',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Chip(
                    label: Text(
                      _getStatusInSpanish(ticket.status),
                      style: TextStyle(
                        color: AppColors.text, // Texto blanco para ambos estados
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: ticket.status == 'sold' 
                        ? AppColors.statusSold 
                        : AppColors.statusReserved,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
