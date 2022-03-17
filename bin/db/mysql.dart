import 'package:mysql1/mysql1.dart';

import '../conf/config.dart';

class Mysql {
  static Mysql? _instance;
  static Mysql? get instance {
    if (_instance == null) {
      _instance = Mysql();
    }
    return _instance;
  }

  static MySqlConnection? conn;
  static const String TABLE_USER = "user";
  static const String TABLE_USER_SESSION = "user_session";

  Future<void> connectDB() async {
    final settings = ConnectionSettings(
      host: Config.dbSettings['host'],
      port: Config.dbSettings['port'],
      user: Config.dbSettings['user'],
      password: Config.dbSettings['password'],
      db: Config.dbSettings['db'],
    );
    try {
      conn = await MySqlConnection.connect(settings);
      print("database connected:${Config.dbSettings['host']}:${Config.dbSettings['port']}");
    } catch (e) {
      print(e);
    }
  }

  static Future<MySqlConnection?> getDB() async {
    if (conn == null) {
      await _instance!.connectDB();
    }
    return conn;
  }
}
