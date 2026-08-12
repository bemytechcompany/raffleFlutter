import 'package:equatable/equatable.dart';

/// Una página de resultados junto al total disponible.
///
/// El total viene de un `COUNT(*)` en SQL, no de la longitud de [items]: hace
/// falta para saber cuántas páginas hay sin traerlas todas.
class Paged<T> extends Equatable {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  const Paged({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  const Paged.empty({this.pageSize = 20})
      : items = const [],
        total = 0,
        page = 0;

  int get totalPages => pageSize <= 0 ? 0 : (total / pageSize).ceil();

  bool get isEmpty => items.isEmpty;
  bool get hasPreviousPage => page > 0;
  bool get hasNextPage => page < totalPages - 1;

  /// Número del primer elemento de la página, empezando en 1. Para textos del
  /// tipo "Boletos 101-200".
  int get firstItemNumber => total == 0 ? 0 : page * pageSize + 1;
  int get lastItemNumber => total == 0 ? 0 : firstItemNumber + items.length - 1;

  @override
  List<Object?> get props => [items, total, page, pageSize];
}
