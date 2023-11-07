import 'dart:convert';
import 'dart:io';

import '../model/message_model.dart';
import '../model/socket_data_model.dart';
import '../model/user_model.dart';
import 'global_dao.dart';

class MessageDao {
  static Future<bool> addMessageWithSocketData(String message, int senderId, int receiverId, Socket? socket) async {
    final _messageDao = GlobalDao("message");
    final _userDao = GlobalDao("user");

    ///查找发送消息的用户
    Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", senderId)]);

    //没有发件人和收件人的消息不执行任何操作
    if (_userJson.isEmpty) {
      return false;
    }

    Map<String, dynamic> _message = MessageModel(
      receiver_id: receiverId,
      sender_id: _userJson['user_id'],
      content: message,
      create_time: DateTime.now(),
    ).toJson();
    _message.remove('id');

    int id = await _messageDao.insertReturnId(_message);

    if (id != 0) {
      ///发送消息至指定用户（若连接存在）
      _message['id'] = id;
      if (socket != null) {
        SocketDataModel _receiveData = SocketDataModel(
          user_id: senderId,
          command: SocketCommand.message,
          message: message,
          extra: {"sender": UserModel.fromJson(_userJson).toJsonBasic(), "message": _message},
          snedTime: DateTime.now(),
        );
        socket.write(jsonEncode(_receiveData.toJson()));
      }
    }

    return id != 0;
  }
}
