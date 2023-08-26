import 'dart:convert';

import 'package:intl/intl.dart';

import '../conf/config.dart';
import '../utils/data_utils.dart';

class Token {
  String token;
  int user_id;
  String device;
  DateTime? disable_time;
  DateTime? update_time;
  DateTime? create_time;

  Token({
    this.token = "",
    this.device = "",
    this.user_id = 0,
    this.create_time,
    this.disable_time,
    this.update_time,
  });

  factory Token.fromJson(Map<String, dynamic>? jsonRes) {
    if (jsonRes == null) {
      return Token();
    } else {
      return Token(
        token: jsonRes['token'],
        device: jsonRes['device'],
        user_id: jsonRes['user_id'],
        create_time: jsonRes['create_time'],
        disable_time: jsonRes['disable_time'],
        update_time: jsonRes['update_time'],
      );
    }
  }

  bool tokenIsAvailable() {
    DateTime _now = DateTime.now();
    DateTime? _time = update_time;
    if (update_time == null) {
      _time = create_time;
    }
    try {
      return _now.difference(DataUtils.formatDateTime(_time!)).inMinutes.abs() <= Config.MAX_TOKEN_TIME;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'device': device,
        'user_id': user_id,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'disable_time': disable_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(disable_time!),
        'update_time': update_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(update_time!),
      };

  static String generateSessionId(int user_id, String pwd, int loginTime) {
    return DataUtils.generate_MD5("$user_id$pwd$loginTime").toUpperCase();
  }
}
