class Releve {
  const Releve({
    required this.id,
    required this.abonneId,
    required this.cumulIndex,
    required this.dateReleve,
    required this.index,
    required this.createdAt,
    this.facturation,
  });

  final String id;
  final String abonneId;
  final String cumulIndex;
  final String dateReleve;
  final String index;
  final DateTime createdAt;
  final Facturation? facturation;

  static Releve fromApi(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final abonneId = json['abonne_id']?.toString() ?? '';
    final cumulIndex = json['cumul_index']?.toString() ?? '0.00';
    final dateReleve = json['date_releve']?.toString() ?? '';
    final index = json['index']?.toString() ?? '0.00';
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now();
    
    Facturation? facturation;
    if (json['facturation'] != null) {
      facturation = Facturation.fromApi(json['facturation']);
    }

    return Releve(
      id: id,
      abonneId: abonneId,
      cumulIndex: cumulIndex,
      dateReleve: dateReleve,
      index: index,
      createdAt: createdAt,
      facturation: facturation,
    );
  }
}

class Facturation {
  const Facturation({
    required this.id,
    required this.releveActuelId,
    required this.consommationM3,
    required this.prixM3,
    required this.montantTotal,
    required this.periode,
    required this.estPaye,
  });

  final String id;
  final String releveActuelId;
  final String consommationM3;
  final String prixM3;
  final String montantTotal;
  final String periode;
  final int estPaye;

  static Facturation fromApi(Map<String, dynamic> json) {
    return Facturation(
      id: json['id']?.toString() ?? '',
      releveActuelId: json['releve_actuel_id']?.toString() ?? '',
      consommationM3: json['consommation_m3']?.toString() ?? '0.00',
      prixM3: json['prix_m3']?.toString() ?? '0.00',
      montantTotal: json['montant_total']?.toString() ?? '0.00',
      periode: json['periode']?.toString() ?? '',
      estPaye: json['est_paye'] ?? 0,
    );
  }
}
