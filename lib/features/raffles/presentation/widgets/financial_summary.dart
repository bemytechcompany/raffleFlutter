import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formateo de porcentajes

import 'package:raffle/core/money/money.dart';
import '../../domain/entities/raffle.dart';
import '../../domain/entities/ticket_counts.dart';

/// Resumen de dinero de una rifa.
///
/// Recibe contadores, no la lista de boletos: los cuenta SQLite y así la
/// pantalla no depende de cuántos boletos tenga la rifa.
class FinancialSummary extends StatelessWidget {
  final Raffle raffle;
  final TicketCounts counts;

  const FinancialSummary({
    super.key,
    required this.raffle,
    required this.counts,
  });

  NumberFormat get percentFormat => NumberFormat.decimalPercentPattern(
        decimalDigits: 1,
        locale: 'es',
      );

  @override
  Widget build(BuildContext context) {
    // Todo en unidades mínimas: aritmética entera, sin error de redondeo.
    final collected = counts.collectedMinor(raffle.priceMinor);
    final pending = counts.reservedMinor(raffle.priceMinor);
    final remaining = counts.remainingMinor(raffle.priceMinor);
    final total = raffle.goalMinor;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white70,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Resumen Financiero',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF383838),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${raffle.totalTickets} Tickets',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Meta De Ventas: ',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              Text(
                Money.format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryBox('Cobrado', collected, counts.soldRatio,
                  const Color(0xFF00E676)),
              _summaryBox('Reservado', pending, counts.reservedRatio,
                  const Color(0xFFFFD54F)),
              _summaryBox('Pendiente', remaining, counts.availableRatio,
                  const Color(0xFF9E9E9E)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _buildProgressBar()),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  percentFormat.format(counts.committedRatio),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ventas: ${Money.format(collected + pending)}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(
      String label, int valueMinor, double percent, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              _getIconForLabel(label),
              color: color,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          Money.format(valueMinor),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          percentFormat.format(percent),
          style: const TextStyle(fontSize: 12, color: Colors.white38),
        ),
      ],
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Cobrado':
        return Icons.check_circle_outline;
      case 'Reservado':
        return Icons.bookmark;
      case 'Pendiente':
        return Icons.access_time;
      default:
        return Icons.question_mark;
    }
  }

  Widget _buildProgressBar() {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(51),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _progressSegment(counts.soldRatio, const Color(0xFF00E676)),
          _progressSegment(counts.reservedRatio, const Color(0xFFFFD54F)),
          _progressSegment(
              counts.availableRatio, const Color(0xFF9E9E9E).withAlpha(77)),
        ],
      ),
    );
  }

  Widget _progressSegment(double percent, Color color) {
    // `flex` tiene que ser un entero positivo: descartamos también NaN e
    // infinitos por si el porcentaje llegara mal calculado.
    if (!percent.isFinite || percent <= 0) return const SizedBox.shrink();

    return Expanded(
      // Multiplicamos por 1000 para no perder precisión al redondear.
      flex: (percent * 1000).round(),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
