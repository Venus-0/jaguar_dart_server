import 'dart:collection';
import 'package:mysql1/mysql1.dart';
import '../api/session.dart';
import 'mysql.dart';

///session管理
class SessionDao {
  ///添加session
  Future<String> loginSession(String account, String pwd) async {
    Session? session = await querySession(account);
    DateTime _now = DateTime.now();
    if (session == null) {
      //没有session添加一个
      session = Session(
          account: account,
          session: Session.generateSessionId(account, pwd, _now.millisecondsSinceEpoch ~/ 1000),
          sessionTime: _now.millisecondsSinceEpoch ~/ 1000,
          loginTime: _now.millisecondsSinceEpoch ~/ 1000);
      await addSession(session);
    } else {
      HashMap<String, dynamic> modifyMap = HashMap();
      modifyMap['loginTime'] = _now.millisecondsSinceEpoch ~/ 1000;
      //当前时间与登陆时间相差30分钟重新生成session
      if (session.sessionIsAvailable()) {
        session.session = Session.generateSessionId(account, pwd, _now.millisecondsSinceEpoch ~/ 1000);
        modifyMap['session'] = session.session;
      }
      await updateSession(account, modifyMap);
    }

    return session.session;
  }

  ///查询session
  Future<Session?> querySession(String account) async {
    MySqlConnection? conn = await Mysql.getDB();
    print("SELECT * FROM ${Mysql.TABLE_USER_SESSION} WHERE account = \"$account\"");
    Results res = await conn.query("SELECT * FROM ${Mysql.TABLE_USER_SESSION} WHERE account = \"$account\"");
    Session? session;
    if (res.isNotEmpty) {
      session = Session.fromJson(res.first.fields);
    }
    return session;
  }

  ///更新session
  Future<void> updateSession(String account, HashMap<String, dynamic> modifyMap) async {
    MySqlConnection? conn = await Mysql.getDB();
    String mod = "";
    modifyMap.forEach((key, value) {
      if (value is String) {
        mod += "$key='$value',";
      } else {
        mod += "$key=$value,";
      }
    });
    mod = mod.substring(0, mod.length - 1);
    print("UPDATE ${Mysql.TABLE_USER_SESSION} SET $mod WHERE account = \"$account\"");
    await conn.query("UPDATE ${Mysql.TABLE_USER_SESSION} SET $mod WHERE account = \"$account\"");
  }

  ///添加session
  Future<void> addSession(Session session) async {
    MySqlConnection? conn = await Mysql.getDB();
    Map<String, dynamic> json = session.toJson();
    String fields = "";
    String values = "";
    json.forEach((key, value) {
      fields += "$key,";
      if (value is String) {
        values += "'$value',";
      } else {
        values += "$value,";
      }
    });
    fields = fields.substring(0, fields.length - 1);
    values = values.substring(0, values.length - 1);
    print("INSERT INTO ${Mysql.TABLE_USER_SESSION} ($fields) VALUES ($values)");
    await conn.query("INSERT INTO ${Mysql.TABLE_USER_SESSION} ($fields) VALUES ($values)");
  }
}
