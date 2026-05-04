import 'package:hive/hive.dart';

part 'worker.g.dart';

@HiveType(typeId: 0)
class Worker extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? phone;

  @HiveField(3)
  final double wageRate;

  @HiveField(4)
  final String email; // Made mandatory for linking

  @HiveField(5)
  final String? businessId; // The Owner's UID

  @HiveField(6)
  final double rating;

  @HiveField(7)
  final String? projectId; // Link to Site

  Worker({
    required this.id,
    required this.name,
    this.phone,
    required this.wageRate,
    required this.email,
    this.businessId,
    this.rating = 0,
    this.projectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'wageRate': wageRate,
      'email': email,
      'businessId': businessId,
      'rating': rating,
      'projectId': projectId,
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      wageRate: (map['wageRate'] ?? 0.0).toDouble(),
      email: map['email'] ?? '',
      businessId: map['businessId'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      projectId: map['projectId'],
    );
  }
}
