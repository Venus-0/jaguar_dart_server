import 'dart:async';

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

  static Timer? _heartBeatTimer;

  static MySqlConnection? conn;
  Future<void> connectDB() async {
    final settings = ConnectionSettings(
      host: Config.dbSettings['host'],
      port: Config.dbSettings['port'],
      user: Config.dbSettings['user'],
      password: Config.dbSettings['password'],
      db: Config.dbSettings['db'],
      maxPacketSize: 512 * 1024 * 1024,
    );
    try {
      conn = await MySqlConnection.connect(settings);
      print("database connected:${Config.dbSettings['host']}:${Config.dbSettings['port']}");
      _startHeartBeatTest();
    } catch (e) {
      print(e);
    }
  }

  static Future<MySqlConnection> getDB() async {
    // await conn?.close();
    if (conn == null) {
      await _instance!.connectDB();
    }
    return conn!;
  }

  ///MySQL连接心跳检测
  ///每15秒做一次查询，查询失败后close连接
  static _startHeartBeatTest() async {
    // print("----------INITIAL MYSQL HEARTBEAT TEST----------");
    _heartBeatTimer?.cancel();
    _heartBeatTimer = Timer.periodic(Duration(milliseconds: 15000), (timer) async {
      // print("-----------START MYSQL HEARTBEAT TEST-----------");
      try {
        if (conn != null) {
          await conn!.query("SELECT VERSION()");
        }
      } on MySqlException catch (e) {
        print("--------------MYSQL HEARTBEAT ERROR-------------");
        _heartBeatTimer?.cancel();
        _heartBeatTimer = null;
        conn?.close();
        conn = null;
        return;
      } on StateError catch (e) {
        print("--------------MYSQL HEARTBEAT ERROR-------------");
        _heartBeatTimer?.cancel();
        _heartBeatTimer = null;
        conn?.close();
        conn = null;
        return;
      }
      // print("-------------MYSQL HEARTBEAT SUCCESS------------");
    });
  }
}
