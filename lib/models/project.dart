import 'package:hive/hive.dart';

// part 'project.g.dart';

@HiveType(typeId: 5)
class Project extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String location;

  @HiveField(3)
  final double contractAmount;

  @HiveField(4)
  final String businessId;

  @HiveField(5)
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.contractAmount,
    required this.businessId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'contractAmount': contractAmount,
      'businessId': businessId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      contractAmount: (map['contractAmount'] ?? 0.0).toDouble(),
      businessId: map['businessId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
