import 'dart:async';

import 'db/mysql.dart';
import 'server.dart';
import 'socket.dart';

void main(List<String> arguments) async {
  runZonedGuarded(() async {
    print('init server...');
    await Server.instance!.initServer();
    print("init database...");
    await Mysql.instance!.connectDB();
    print("init socket...");
    await SocketManager.instance.init();
  }, (e, t) {
    print("------------------------------");
    print("------------ERROR-------------");
    print(e.runtimeType);
    print(e);
    print(t);
    print("------------------------------");
  });
}
