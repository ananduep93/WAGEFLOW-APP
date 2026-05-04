// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkerAdapter extends TypeAdapter<Worker> {
  @override
  final int typeId = 0;

  @override
  Worker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Worker(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      wageRate: fields[3] as double,
      email: fields[4] as String,
      businessId: fields[5] as String?,
      rating: fields[6] as double,
      projectId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Worker obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.wageRate)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.businessId)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.projectId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
