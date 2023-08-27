import 'dart:convert';

import 'package:intl/intl.dart';

///用户数据模型
class UserModel {
  int user_id; //用户id
  String password = ""; //用户密码（MD5）
  String email = ""; //用户邮箱
  String username = ""; //用户名
  String avatar = ""; //用户头像
  DateTime? disable_time; //用户禁用时间
  DateTime? update_time; //用户更新时间
  DateTime? create_time; //用户创建时间

  UserModel({
    this.user_id = 0,
    this.password = "",
    this.email = "",
    this.avatar = "",
    this.username = "",
    this.create_time,
    this.disable_time,
    this.update_time,
  });

  factory UserModel.fromJson(Map<String, dynamic>? jsonRes) {
    if (jsonRes == null) {
      return UserModel();
    } else {
      return UserModel(
        user_id: jsonRes['user_id'],
        password: jsonRes['password'],
        email: jsonRes['email'],
        username: jsonRes['username'],
        avatar: jsonRes['avatar'],
        create_time: jsonRes['create_time'],
        disable_time: jsonRes['disable_time'],
        update_time: jsonRes['update_time'],
      );
    }
  }

  Map<String, dynamic> toJson() => {
        "user_id": user_id,
        "password": password,
        "username": username,
        "email": email,
        "avatar": avatar,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'disable_time': disable_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(disable_time!),
        'update_time': update_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(update_time!),
      };
}
