import 'package:equatable/equatable.dart';

class Participant extends Equatable {
  final int? id;
  final int giveawayId;
  final String name;
  final String contact;
  final bool isPreselected;
  final bool isWinner;
  final String? award;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Participant({
    this.id,
    required this.giveawayId,
    required this.name,
    required this.contact,
    this.isPreselected = false,
    this.isWinner = false,
    this.award,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Sigue en el bombo: fue preseleccionado y todavía no le ha tocado.
  ///
  /// `isPreselected` no se apaga al ganar porque es lo que le dice al sorteo
  /// que hubo preselección —si se borrara, la siguiente ronda repescaría a
  /// quien nunca entró—. Para contar cuántos quedan por salir se usa esto.
  bool get isPendingPreselection => isPreselected && !isWinner;

  @override
  List<Object?> get props => [
        id,
        giveawayId,
        name,
        contact,
        isPreselected,
        isWinner,
        award,
        createdAt,
        updatedAt,
      ];
}
