import 'package:intl/intl.dart';

class SubscribeModel {
  static const int TYPE_USER = 1; //关注类型-用户
  static const int TYPE_POST = 2; //关注类型-帖子
  static const List<int> TYPES = [1, 2];
  int id;
  int user_id;
  int subscribe_id;
  int subscribe_type;
  DateTime? create_time;
  DateTime? delete_time;

  SubscribeModel({
    this.id = 0,
    this.user_id = 0,
    this.subscribe_id = 0,
    this.subscribe_type = 0,
    this.create_time,
    this.delete_time,
  });

  factory SubscribeModel.fromJson(Map<String, dynamic> json) {
    return SubscribeModel(
      id: json['id'],
      user_id: json['user_id'],
      subscribe_id: json['subscribe_id'],
      subscribe_type: json['subscribe_type'],
      create_time: json['create_time'],
      delete_time: json['delete_time'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': user_id,
        'subscribe_id': subscribe_id,
        'subscribe_type': subscribe_type,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'delete_time': delete_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(delete_time!),
      };
}
