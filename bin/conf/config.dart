class Config {
  static const Map<String, dynamic> dbSettings = {
    "host": "127.0.0.1",
    "port": 3306,
    "user": "root",
    "password": "root",
    "db": "bbs",
    "max_allowed_packet": 1024 * 1024 * 1024,
  };

  static const int MAX_TOKEN_TIME = 30 * 24 * 60; //token最大有效期时间  单位分钟

  static const Map<String, dynamic> emailSenderConfig = {
    "userName": "949052312@qq.com",
    "authorization": "",
  };

  static const int MIN_USER_PASSWORD_LENGTH = 8; //账户密码最短配置
}
