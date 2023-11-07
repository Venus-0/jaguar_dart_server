class Config {
  static const Map<String, dynamic> dbSettings = {
    "host": "43.139.90.52",
    "port": 3306,
    "user": "root",
    "password": "Wyx981007!",
    "db": "bbs"
    // "host": "127.0.0.1",
    // "port": 3306,
    // "user": "root",
    // "password": "root",
    // "db": "bbs"
  };

  static const int MAX_TOKEN_TIME = 30 * 24 * 60; //token最大有效期时间  单位分钟

  static const Map<String, dynamic> emailSenderConfig = {
    "userName": "949052312@qq.com",
    "authorization": "ouoizdaevawzbdcd",
  };
}
