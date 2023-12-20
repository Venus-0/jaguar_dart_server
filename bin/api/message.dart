import 'dart:async';

import 'package:intl/intl.dart';
import 'package:jaguar/http/context/context.dart';
import 'package:jaguar/http/response/response.dart';

import '../db/global_dao.dart';
import '../db/message_dao.dart';
import '../model/message_model.dart';
import '../model/user_model.dart';
import '../socket.dart';
import 'base_api.dart';

class Message extends BaseApi {
  Message(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) async {
    if (!(await validateToken())) return tokenExpired;
    if (method == 'getMessageList') return _getMessageList(); //获取消息列表
    if (method == 'getUnReadMessage') return _getUnReadMessage(); //获取未读消息数量
    if (method == 'readMessage') return _readMessage(); //已读消息
    if (method == 'sendMessgae') return _sendMessgae(); //发消息
    if (method == "getUserMessage") return _getUserMessage(); //获取指定用户的聊天记录
    return pageNotFound;
  }

  ///获取消息列表
  FutureOr<Response> _getMessageList() async {
    final _user = await getTokenUser();
    if (_user == null) return userNotFind;

    final _messageDao = GlobalDao("message");
    final _userDao = GlobalDao("user");

    ///查发送人和收件人都是当前用户的消息
    List<Map<String, dynamic>> _messgaeJsons = await _messageDao
        .getList(where: [Where("receiver_id", _user.user_id, "=", "or"), Where("sender_id", _user.user_id)], order: "create_time DESC");
    Map<String, dynamic> _messages = {};
    for (final json in _messgaeJsons) {
      MessageModel _message = MessageModel.fromJson(json);
      if (_message.receiver_id == _user.user_id) {
        ///收件人是当前用户查发送人
        if (_messages["${_message.sender_id}"] == null) {
          Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", _message.sender_id)]);
          if (_userJson.isNotEmpty) {
            _messages["${_message.sender_id}"] = {
              "user": UserModel.fromJson(_userJson).toJsonBasic(),
              "messages": <Map<String, dynamic>>[]
            };
          } else {
            continue;
          }
        }
        (_messages["${_message.sender_id}"]['messages'] as List<Map<String, dynamic>>).add(_message.toJson());
      } else if (_message.sender_id == _user.user_id) {
        ///发送人是当前用户查收件人
        if (_messages["${_message.receiver_id}"] == null) {
          Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", _message.receiver_id)]);
          if (_userJson.isNotEmpty) {
            _messages["${_message.receiver_id}"] = {
              "user": UserModel.fromJson(_userJson).toJsonBasic(),
              "messages": <Map<String, dynamic>>[]
            };
          } else {
            continue;
          }
        }
        (_messages["${_message.receiver_id}"]['messages'] as List<Map<String, dynamic>>).add(_message.toJson());
      } else {
        continue;
      }
    }

    return packData(SUCCESS, _messages, "OK");
  }

  ///获取未读消息数量
  FutureOr<Response> _getUnReadMessage() async {
    final _user = await getTokenUser();
    if (_user == null) return userNotFind;

    final _messageDao = GlobalDao("message");
    Map<String, dynamic> _unReadCount =
        await _messageDao.getOne(column: ["COUNT(*)"], where: [Where("receiver_id", _user.user_id), Where("read_time", null, "IS")]);
    return packData(SUCCESS, {"count": _unReadCount["COUNT(*)"] ?? 0}, "OK");
  }

  ///已读消息
  FutureOr<Response> _readMessage() async {
    final _user = await getTokenUser();
    if (_user == null) return userNotFind;
    int _senderId = await get("sender_id");
    if (_senderId == 0) return packData(ERROR, null, "id不能为空");

    final _messageDao = GlobalDao("message");

    ///查有没有消息
    final _list = await _messageDao.getList(where: [Where("receiver_id", _user.user_id), Where("sender_id", _senderId)]);
    if (_list.isEmpty) return packData(SUCCESS, null, "没有未读消息");
    Map<String, dynamic> _modify = {"read_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())};
    bool _ret = await _messageDao.update(_modify, where: [Where("receiver_id", _user.user_id), Where("sender_id", _senderId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "ERROR");
    }
  }

  ///发送消息
  FutureOr<Response> _sendMessgae() async {
    final _user = await getTokenUser();
    if (_user == null) return userNotFind;
    String _message = await get<String>("message");
    int _receiverId = await get<int>("receiver_id");
    if (_message.isEmpty) return packData(ERROR, null, "消息不能为空");
    bool _ret =
        await MessageDao.addMessageWithSocketData(_message, _user.user_id, _receiverId, SocketManager.instance.userSockets[_receiverId]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "OERROR");
    }
  }

  ///获取指定用户的聊天记录
  FutureOr<Response> _getUserMessage() async {
    final _currentUser = await getTokenUser();
    if (_currentUser == null) return userNotFind;
    int _userId = await get<int>("user_id");
    final _userDao = GlobalDao("user");
    Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", _userId)]);
    if (_userJson.isEmpty) return packData(ERROR, null, "查无此人");
    UserModel _user = UserModel.fromJson(_userJson);
    final _messageDao = GlobalDao("message");
    List<Map<String, dynamic>> _messgaeJsons = await _messageDao.getList(where: [
      Where("receiver_id", _currentUser.user_id),
      Where("sender_id", _user.user_id, "=", "or"),
      Where("receiver_id", _user.user_id),
      Where("sender_id", _currentUser.user_id),
    ], order: "create_time DESC");
    List<Map<String, dynamic>> _list = [];

    for (final json in _messgaeJsons) {
      MessageModel _message = MessageModel.fromJson(json);
      _list.add(_message.toJson());
    }

    return packData(SUCCESS, {"list": _list}, "OK");
  }
}
