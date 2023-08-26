import 'dart:collection';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import '../model/token_model.dart';
import 'global_dao.dart';
import 'mysql.dart';

///session管理
class SessionDao {
  late GlobalDao globalDao;
  SessionDao() {
    globalDao = GlobalDao("token");
  }

  ///添加session
  Future<String> loginSession(int user_id, String pwd, String device) async {
    Token? token = await querySession(user_id);
    DateTime _now = DateTime.now();
    if (token == null) {
      //没有session添加一个
      token = Token(
        token: Token.generateSessionId(user_id, pwd, _now.millisecondsSinceEpoch ~/ 1000),
        device: device,
        user_id: user_id,
        create_time: _now,
        update_time: _now,
      );
      await addSession(token);
    } else {
      HashMap<String, dynamic> modifyMap = HashMap();
      modifyMap['update_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(_now);
      //当前时间与登陆时间相差30分钟重新生成session
      if (token.tokenIsAvailable()) {
        token.token = Token.generateSessionId(user_id, pwd, _now.millisecondsSinceEpoch ~/ 1000);
        modifyMap['token'] = token.token;
      }
      await updateSession(user_id, modifyMap);
    }

    return token.token;
  }

  ///查询session
  Future<Token?> querySession(int user_id) async {
    Map<String, dynamic> _token = await globalDao.getOne(where: [Where("user_id", user_id)]);
    Token? _session;
    if (_token.isNotEmpty) {
      _session = Token.fromJson(_token);
    }
    return _session;
  }

  ///更新session
  Future<bool> updateSession(int user_id, HashMap<String, dynamic> modifyMap) async {
    return await globalDao.update(modifyMap, where: [Where("user_id", user_id)]);
  }

  ///添加session
  Future<bool> addSession(Token session) async {
    Map<String, dynamic> _sessionJson = session.toJson();
    return await globalDao.insert(_sessionJson);
  }
}
