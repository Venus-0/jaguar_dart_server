import 'dart:async';

import 'db/mysql.dart';
import 'server.dart';

void main(List<String> arguments) async {
  runZoned(() async {
    print('init server...');
    await Server.instance!.initServer();
    print("init database...");
    await Mysql.instance!.connectDB();
  });
}
