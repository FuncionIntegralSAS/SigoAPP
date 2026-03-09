import 'package:equatable/equatable.dart';

import 'person_model.dart'; // Asegúrate de que este archivo existe y se importa correctamente

class PhysicalCountRequest extends Equatable {
  final String companyId;
  final String warehouseId; // Puede ser 'All' o ID específico
  final DateTime date;
  final String articleId; // Puede ser 'All' o ID específico
  final bool verifyExistence;
  final List<PersonModel> participants;

  const PhysicalCountRequest({
    required this.companyId,
    required this.warehouseId,
    required this.date,
    required this.articleId,
    required this.verifyExistence,
    required this.participants,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'warehouseId': warehouseId,
      'date': date.toIso8601String(),
      'articleId': articleId,
      'verifyExistence': verifyExistence,
      'participantsIds': participants.map((p) => p.nationalId).toList(), 
    };
  }

  @override
  List<Object?> get props => [
    companyId,
    warehouseId,
    date,
    articleId,
    verifyExistence,
    participants,
  ];
}
