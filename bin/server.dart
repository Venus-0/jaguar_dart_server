import 'dart:async';
import 'dart:convert';

import 'package:jaguar/jaguar.dart';

import 'api/base_api.dart';
import 'api/bbs.dart';
import 'api/common.dart';
import 'api/user.dart';

class Server {
  static const int ERROR = 403;
  static const int SUCCESS = 200;
  static const int NOT_FOUND = 404;
  static const int TOKEN_EXPIRED = 401;
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
  }

  Future<void> initServer() async {
    if (server == null && !isInit) {
      server = new Jaguar(address: '0.0.0.0', port: port)
        // ..staticFiles("/*", 'bin')
        ..post('/api/*', handler)
        ..get('/api/*', handler);
      await server!.serve();
      print("local server opened , port:$port");
      isInit = true;
    }
  }

  FutureOr<dynamic> handler(Context ctx) async {
    print(ctx.uri.toString());
    print(ctx.uri.toString().split("/"));
    List<String> _addres = ctx.uri.toString().split("/")..removeAt(0);

    print(_addres);
    if (_addres.length < 3) {
      ctx.response = Response(body: jsonEncode({}), statusCode: NOT_FOUND);
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
      ctx.response = Response(body: jsonEncode({}), statusCode: NOT_FOUND);
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
