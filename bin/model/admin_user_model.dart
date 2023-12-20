import 'package:intl/intl.dart';

class AdminUserModel {
  int admin_id;
  String password;
  String name;
  int rank;
  DateTime? create_time;
  DateTime? delete_time;
  DateTime? login_time;
  String white_ip;

  AdminUserModel({
    this.admin_id = 0,
    this.password = '',
    this.name = '',
    this.rank = 0,
    this.create_time,
    this.delete_time,
    this.login_time,
    this.white_ip = '',
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) => AdminUserModel(
        admin_id: json['admin_id'],
        password: json['password'],
        name: json['name'],
        rank: json['rank'],
        create_time: json['create_time'],
        delete_time: json['delete_time'],
        login_time: json['login_time'],
        white_ip: json['white_ip'],
      );

  Map<String, dynamic> toJson() => {
        'admin_id': admin_id,
        'password': password,
        'name': name,
        'rank': rank,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'delete_time': delete_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(delete_time!),
        'login_time': login_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(login_time!),
        'white_ip': white_ip,
      };
  Map<String, dynamic> toJsonBasic() => {
        'admin_id': admin_id,
        'name': name,
        'rank': rank,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'delete_time': delete_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(delete_time!),
        'login_time': login_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(login_time!),
        'white_ip': white_ip,
      };
}
