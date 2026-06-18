class VaccinationModel {
  final String? id;
  final String petId;
  final String vaccineName;
  final String date;
  final String? nextSchedule;

  VaccinationModel({
    this.id,
    required this.petId,
    required this.vaccineName,
    required this.date,
    this.nextSchedule,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'],
      petId: json['pet_id'],
      vaccineName: json['vaccine_name'],
      date: json['date'],
      nextSchedule: json['next_schedule'],
    );
  }
}

class TreatmentModel {
  final String? id;
  final String petId;
  final String date;
  final String diagnosis;
  final String? medicine;

  TreatmentModel({
    this.id,
    required this.petId,
    required this.date,
    required this.diagnosis,
    this.medicine,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'],
      petId: json['pet_id'],
      date: json['date'],
      diagnosis: json['diagnosis'],
      medicine: json['medicine'],
    );
  }
}

class AllergyModel {
  final String? id;
  final String petId;
  final String allergen;
  final String reaction;

  AllergyModel({
    this.id,
    required this.petId,
    required this.allergen,
    required this.reaction,
  });

  factory AllergyModel.fromJson(Map<String, dynamic> json) {
    return AllergyModel(
      id: json['id'],
      petId: json['pet_id'],
      allergen: json['allergen'],
      reaction: json['reaction'],
    );
  }
}