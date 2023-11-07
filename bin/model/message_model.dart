import 'package:intl/intl.dart';

class MessageModel {
  int id; //消息id
  int receiver_id; //收信人id
  int sender_id; //发信人id
  String content; //消息正文
  DateTime? create_time; //创建时间
  DateTime? read_time; //收信人已读时间
  MessageModel({
    this.id = 0,
    this.receiver_id = 0,
    this.sender_id = 0,
    this.content = '',
    this.create_time,
    this.read_time,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      receiver_id: json['receiver_id'],
      sender_id: json['sender_id'],
      content: json['content'],
      create_time: json['create_time'],
      read_time: json['read_time'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiver_id': receiver_id,
        'sender_id': sender_id,
        'content': content,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'read_time': read_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(read_time!),
      };
}
