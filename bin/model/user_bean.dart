import 'dart:convert';

class User {
  String account = "";
  String password = "";
  String nickname = "";

  User({this.account = "", this.password = "", this.nickname = ""});

  factory User.fromJson(Map<String, dynamic>? jsonRes) {
    if (jsonRes == null) {
      return User();
    } else {
      return User(account: jsonRes['account'], password: jsonRes['password'], nickname: jsonRes['nickname']);
    }
  }

  Map<String, dynamic> toJson() => {"account": account, "password": password, "nickname": nickname};
}
