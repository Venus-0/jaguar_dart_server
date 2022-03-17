import 'dart:convert';

import '../utils/data_utils.dart';

class Session {
  String account = "";
  String session = "";
  int sessionTime = 0;
  int loginTime = 0;

  Session({this.account = "", this.loginTime = 0, this.session = "", this.sessionTime = 0});

  factory Session.fromJson(Map<String, dynamic>? jsonRes) {
    if (jsonRes == null) {
      return Session();
    } else {
      return Session(
        account: jsonRes['account'],
        loginTime: jsonRes['loginTime'],
        session: jsonRes['session'],
        sessionTime: jsonRes['sessionTime'],
      );
    }
  }

  bool sessionIsAvailable() {
    DateTime _now = DateTime.now();
    if (loginTime == 0) {
      return false;
    } else {
      return _now.difference(DateTime.fromMillisecondsSinceEpoch(loginTime * 1000)).inMinutes.abs() > 30;
    }
  }

  Map<String, dynamic> toJson() => {
        'account': account,
        'loginTime': loginTime,
        'session': session,
        'sessionTime': sessionTime,
      };

  static String generateSessionId(String account, String pwd, int loginTime) {
    return DataUtils.generate_MD5("$account$pwd$loginTime").toUpperCase();
  }
}
