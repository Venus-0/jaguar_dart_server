import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';

///图片类
class ImageModel {
  int id;
  Blob? file_data;
  DateTime? create_time;
  int type;
  int type_id;
  int user_id;
  ImageModel({
    this.id = 0,
    this.file_data,
    this.create_time,
    this.type = 0,
    this.type_id = 0,
    this.user_id = 0,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      file_data: json['file_data'],
      create_time: json['create_time'],
      type: json['type'],
      type_id: json['type_id'],
      user_id: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_data': file_data,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'type': type,
        'type_id': type_id,
        'user_id': user_id,
      };
}
