import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';

class NoticeModel {
  int id;
  int admin_id;
  String title;
  String content;
  Blob? image;
  DateTime? create_time;
  DateTime? delete_time;
  NoticeModel({
    this.id = 0,
    this.admin_id = 0,
    this.title = "",
    this.content = "",
    this.create_time,
    this.delete_time,
    this.image,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    Blob? _image;
    if (json['image'] is Blob) {
      _image = json['image'];
    } else if (json['image'] is String) {
      _image = Blob.fromBytes(base64Decode(json['image'].toString().split(",").last));
    }
    print(base64Encode(_image!.toBytes()));
    File file = File('D:/code_demo/64.txt');
    file.writeAsStringSync(_image.toString());
    return NoticeModel(
      id: json['id'],
      admin_id: json['admin_id'],
      title: json['title'],
      content: json['content'],
      image: _image,
      create_time: json['create_time'],
      delete_time: json['delete_time'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'admin_id': admin_id,
        'title': title,
        'content': content,
        'image': image,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'delete_time': delete_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(delete_time!),
      };

  Map<String, dynamic> toJsonBase64() => {
        'id': id,
        'admin_id': admin_id,
        'title': title,
        'content': content,
        'image': image == null ? "" : base64Encode(image!.toBytes()),
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'delete_time': delete_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(delete_time!),
      };
}
