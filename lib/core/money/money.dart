import 'package:intl/intl.dart';

/// Manejo de importes en unidades mínimas (centavos).
///
/// El dinero se guarda y se opera siempre como `int`. Multiplicar el precio
/// por miles de boletos con `double` acumula error de coma flotante, y el
/// resumen financiero es justo la pantalla donde eso se nota. La conversión a
/// decimal ocurre solo al final, al formatear para mostrar.
class Money {
  Money._();

  /// Centavos por unidad monetaria.
  static const int minorPerUnit = 100;

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
    locale: 'es',
  );

  /// Formatea un importe en unidades mínimas: `150000` → `$1.500,00`.
  static String format(int minorUnits) {
    return _currencyFormat.format(minorUnits / minorPerUnit);
  }

  /// Convierte lo que escribe el usuario a unidades mínimas.
  ///
  /// Acepta coma o punto como separador decimal. Devuelve `null` si el texto
  /// no es un número válido, para que el validador del formulario decida.
  static int? tryParse(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;

    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite) return null;

    return (value * minorPerUnit).round();
  }

  /// Representación editable de un importe, para precargar formularios.
  ///
  /// Devuelve `1500` en vez de `1500.0` cuando no hay centavos.
  static String toEditableString(int minorUnits) {
    if (minorUnits % minorPerUnit == 0) {
      return (minorUnits ~/ minorPerUnit).toString();
    }
    return (minorUnits / minorPerUnit).toStringAsFixed(2);
  }
}
