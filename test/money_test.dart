import 'package:flutter_test/flutter_test.dart';
import 'package:raffle/core/money/money.dart';

void main() {
  group('Money.tryParse', () {
    test('convierte a unidades mínimas', () {
      expect(Money.tryParse('1000'), 100000);
      expect(Money.tryParse('1000.50'), 100050);
    });

    test('acepta coma como separador decimal', () {
      expect(Money.tryParse('1000,50'), 100050);
    });

    test('ignora espacios alrededor', () {
      expect(Money.tryParse('  250 '), 25000);
    });

    test('devuelve null si no es un número', () {
      expect(Money.tryParse(''), isNull);
      expect(Money.tryParse('abc'), isNull);
    });
  });

  group('Money.toEditableString', () {
    test('omite los decimales cuando no los hay', () {
      expect(Money.toEditableString(100000), '1000');
    });

    test('los conserva cuando los hay', () {
      expect(Money.toEditableString(100050), '1000.50');
    });
  });

  test('sumar miles de boletos no acumula error de redondeo', () {
    // Con double, 0.1 sumado 10.000 veces no da exactamente 1000.
    // Este es el motivo de guardar el dinero como entero.
    const priceMinor = 10; // $0,10
    const ticketCount = 10000;

    expect(priceMinor * ticketCount, 100000); // exactamente $1.000,00
  });
}
