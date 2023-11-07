import 'dart:async';
import 'dart:convert';

import 'package:jaguar/jaguar.dart';

import 'api/admin.dart';
import 'api/base_api.dart';
import 'api/bbs.dart';
import 'api/common.dart';
import 'api/message.dart';
import 'api/user.dart';

class Server {
  static const int port = 8080;
  static const String GET = "GET";
  static const String POST = "POST";

  bool isInit = false;
  Jaguar? server;
  static Server? _instance;
  static Server? get instance {
    if (_instance == null) {
      _instance = Server();
    }
    return _instance;
  }

  ///过滤器
  BaseApi? _filter(Context ctx, String method) {
    if (method == "user") return User(ctx);
    if (method == "common") return Common(ctx);
    if (method == "bbs") return BBS(ctx);
    if (method == "admin") return Admin(ctx);
    if (method == "message") return Message(ctx);
  }

  Future<void> initServer() async {
    if (server == null && !isInit) {
      server = new Jaguar(address: '0.0.0.0', port: port, multiThread: true)
        // ..staticFiles("/*", 'bin')
        ..post('/api/*', handler)
        ..get('/api/*', handler);
      await server!.serve();
      print("local server opened , port:$port");
      isInit = true;
    }
  }

  FutureOr<dynamic> handler(Context ctx) async {
    List<String> _addres = (ctx.uri.toString().split("?")[0].toString().split("/"))..removeAt(0);
    print(_addres);
    if (_addres.length < 3) {
      ctx.response = Response(body: jsonEncode({}), statusCode: 404);
      return;
    }
    String _keyMethod = _addres[1];
    String _subMethod = _addres[2];

    Response? _response;
    BaseApi? controller = _filter(ctx, _keyMethod);
    if (controller != null) {
      _response = await controller.method(_subMethod);
    }
    if (_response != null) {
      ctx.response = _response;
    } else {
      ctx.response = Response(body: jsonEncode({"code": 404, "msg": "未定义的路由", "result": null}), statusCode: 404);
    }
  }

  int? getEnd(String url) {
    if (url.contains('?')) {
      return url.indexOf('?');
    } else {
      return null;
    }
  }
}
