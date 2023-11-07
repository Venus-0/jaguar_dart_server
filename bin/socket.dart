import 'dart:convert';
import 'dart:io';

import 'db/message_dao.dart';
import 'model/socket_data_model.dart';

class SocketManager {
  static const int SOCKET_PORT = 8082;
  static SocketManager? _instance;
  static SocketManager get instance {
    if (_instance == null) {
      _instance = SocketManager();
    }
    return _instance!;
  }

  ServerSocket? _serverSocket;
  Map<int, Socket> userSockets = {};

  Future<void> init() async {
    _serverSocket = await ServerSocket.bind('127.0.0.1', SOCKET_PORT);
    _serverSocket!.listen((event) {
      var tmpData = "";
      event.cast<List<int>>().transform(utf8.decoder).listen((s) {
        tmpData = _parseSocketJson(event, tmpData, s);
      });
    }, onDone: () {
      _serverSocket!.close().then((_) {
        print(DateTime.now().toString() + "Socket reboot ...");
        init();
      });
    }, onError: (e) {
      _serverSocket!.close().then((_) {
        print(DateTime.now().toString() + "Socket error $e");
        print(DateTime.now().toString() + "Socket reboot ...");
        init();
      });
    });
    print(DateTime.now().toString() + "Socket opened in port $SOCKET_PORT ...");
  }

  String _parseSocketJson(Socket socket, String sData, String s) {
    var tmpData = sData + s;

    print(s);
    print("-----------------------------------------");
    print(tmpData);
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    // 找这个串里有没有相应的JSON符号
    // 没有的话，将数据返回等下一个包
    var bHasJSON = tmpData.contains("{") && tmpData.contains("}");
    if (!bHasJSON) {
      return tmpData;
    }

    //找有类似JSON串，看"{"是否在"}"的前面，
    //在前面，则解析，解析失败，则继续找下一个"}"
    //解析成功，则进行业务处理
    //处理完成，则对剩余部分递归解析，直到全部解析完成（此项一般用不到，仅适用于一次发两个以上的JSON串才需要，
    //每次只传一个JSON串的情况下，是不需要的）
    int idxStart = tmpData.indexOf("{");
    int idxEnd = 0;
    while (tmpData.contains("}", idxEnd)) {
      idxEnd = tmpData.indexOf("}", idxEnd) + 1;
      print('{}=>' + idxStart.toString() + "--" + idxEnd.toString());
      if (idxStart >= idxEnd) {
        continue; // 找下一个 "}"
      }

      var sJSON = tmpData.substring(idxStart, idxEnd);
      print("解析 JSON ...." + sJSON);
      try {
        var jsondata = jsonDecode(sJSON); //解析成功，则说明结束，否则抛出异常，继续接收
        print("解析 JSON OK :" + jsondata.toString());
        // socket.write("解析 JSON OK :" + jsondata.toString());
        ///此处加入要处理的业务方法，一般调用另外一个方法进行下一步处理
        handleSocketData(socket, jsondata);

        tmpData = tmpData.substring(idxEnd); //剩余未解析部分
        idxEnd = 0; //复位

        if (tmpData.contains("{") && tmpData.contains("}")) {
          tmpData = _parseSocketJson(socket, tmpData, "");
          break;
        }
      } catch (err) {
        print("解析 JSON 出错:" + err.toString() + ' waiting for next "}"....'); //抛出异常，继续接收，等下一个}
      }
    }
    return tmpData;
  }

  void handleSocketData(Socket socket, Map<String, dynamic> jsonData) async {
    //检查数据完整性
    if (!SocketDataModel.checkJson(jsonData)) {
      SocketDataModel _replyData = SocketDataModel(
        user_id: 1,
        command: SocketCommand.error,
        message: "消息不完整",
        extra: {"code": 400},
        snedTime: DateTime.now(),
      );

      socket.write(jsonEncode(_replyData.toJson()));
    } else {
      ///处理数据
      SocketDataModel _data = SocketDataModel.fromJson(jsonData);
      switch (_data.command) {
        case SocketCommand.unknow:
          SocketDataModel _replyData = SocketDataModel(
            user_id: 1,
            command: SocketCommand.error,
            message: "未知的命令",
            extra: {"code": 400},
            snedTime: DateTime.now(),
          );
          socket.write(jsonEncode(_replyData.toJson()));
          break;
        case SocketCommand.heartBeat:
          print(DateTime.now().toString() + "接收到一个心跳包");

          ///接收到心跳包但连接池没有对应连接则加一个
          if (userSockets[_data.user_id] == null) {
            print(DateTime.now().toString() + "[socket] 添加${_data.user_id}的连接");
            userSockets[_data.user_id] = socket;
          }

          ///收到心跳包之后回复一个空包
          SocketDataModel _replyData = SocketDataModel(
            user_id: 1,
            command: SocketCommand.heartBeat,
            message: "OK",
            extra: {},
            snedTime: DateTime.now(),
          );
          socket.write(jsonEncode(_replyData.toJson()));
          break;
        case SocketCommand.message:
          // int _receiveUserId = _data.extra['receiverId'] ?? 0;

          // ///消息入库
          // MessageDao.addMessageWithSocketData(_data, _userSockets[_receiveUserId]).then((ret) {
          //   SocketDataModel _replyData = SocketDataModel(
          //     user_id: 1,
          //     command: SocketCommand.message,
          //     message: "OK",
          //     extra: {"code": 200},
          //     snedTime: DateTime.now(),
          //   );
          //   if (!ret) {
          //     _replyData.message = "ERROR";
          //     _replyData.extra = {"code": 400};
          //   }

          //   ///回执
          //   socket.write(jsonEncode(_replyData.toJson()));
          // });
          break;
        case SocketCommand.error:
          break;
        case SocketCommand.connect:
          // 接收到连接的指令 添加客户端socket到连接池
          if (userSockets[_data.user_id] != null) {
            print(DateTime.now().toString() + "[socket] 已存在${_data.user_id}的连接，清除");
            await userSockets[_data.user_id]?.flush();
            await userSockets[_data.user_id]?.close();
          }
          print(DateTime.now().toString() + "[socket] 添加${_data.user_id}的连接");
          if (_data.user_id != 0) {
            userSockets[_data.user_id] = socket;
            SocketDataModel _replyData = SocketDataModel(
              user_id: 1,
              command: SocketCommand.connect,
              message: "OK",
              extra: {"code": 200},
              snedTime: DateTime.now(),
            );
            socket.write(jsonEncode(_replyData.toJson()));
          }

          break;
      }
    }
  }
}
