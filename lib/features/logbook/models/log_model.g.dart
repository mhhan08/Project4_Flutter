// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogModelAdapter extends TypeAdapter<LogModel> {
  @override
  final int typeId = 0;

  @override
  LogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogModel(
      id: fields[0] as String?,
      title: fields[1] as String,
      description: fields[2] as String,
      date: fields[3] as String,
      authorId: fields[4] as String,
      teamId: fields[5] as String,
      category: fields[6] as LogCategory,
      isPublic: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LogModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.authorId)
      ..writeByte(5)
      ..write(obj.teamId)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.isPublic);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogCategoryAdapter extends TypeAdapter<LogCategory> {
  @override
  final int typeId = 1;

  @override
  LogCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogCategory.pekerjaan;
      case 1:
        return LogCategory.pribadi;
      case 2:
        return LogCategory.belajar;
      case 3:
        return LogCategory.catatanPenting;
      case 4:
        return LogCategory.other;
      default:
        return LogCategory.pekerjaan;
    }
  }

  @override
  void write(BinaryWriter writer, LogCategory obj) {
    switch (obj) {
      case LogCategory.pekerjaan:
        writer.writeByte(0);
        break;
      case LogCategory.pribadi:
        writer.writeByte(1);
        break;
      case LogCategory.belajar:
        writer.writeByte(2);
        break;
      case LogCategory.catatanPenting:
        writer.writeByte(3);
        break;
      case LogCategory.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
