import 'package:intl/intl.dart';

enum SocketCommand {
  unknow, //未知指令
  connect, //连接
  heartBeat, //心跳包
  message, //消息
  error, //错误回复
}

class SocketDataModel {
  static const _commandMap = <int, SocketCommand>{
    0: SocketCommand.unknow,
    1: SocketCommand.connect,
    2: SocketCommand.heartBeat,
    3: SocketCommand.message,
    4: SocketCommand.error,
  };

  int user_id; //用户id   从server发出的id默认为1
  SocketCommand command; //消息类型（命令）
  String message; //消息主题
  Map<String, dynamic> extra; //额外信息
  DateTime? snedTime; //接收的时间

  SocketDataModel({
    this.user_id = 0,
    this.command = SocketCommand.unknow,
    this.message = "",
    this.extra = const {},
    this.snedTime,
  });

  factory SocketDataModel.fromJson(Map<String, dynamic> json) {
    return SocketDataModel(
      user_id: json['user_id'],
      command: _commandMap[json['command'] ?? 0] ?? SocketCommand.unknow,
      message: json['message'] ?? '',
      extra: json['extra'] ?? {},
      snedTime: DateFormat("yyyy-MM-dd HH:mm:ss").parse(json['snedTime']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': user_id,
        'command': SocketCommand.values.indexOf(command),
        'message': message,
        'extra': extra,
        'snedTime': snedTime == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(snedTime!),
      };

  ///验证消息结构完整性
  static bool checkJson(Map<String, dynamic> json) {
    if (json['user_id'] == null) return false;
    if (json['command'] == null) return false;
    if (json['message'] == null) return false;
    if (json['extra'] == null) return false;
    if (json['snedTime'] == null) return false;
    return true;
  }
}
