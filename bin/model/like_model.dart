import 'package:intl/intl.dart';

///点赞数据模型
class LikeModel {
  ///点赞类型
  static const int TYPE_QUESTION = 1; //问题
  static const int TYPE_ANSWER = 2; //回答
  static const int TYPE_COMMENT = 3; //评论
  static const int TYPE_ARTICLE = 4; //文章
  static const int TYPE_POST = 5; //帖子

  int user_id; //点赞的用户id
  int up_type; //点赞类型
  int up_id; //点赞的id
  DateTime? create_time; //创建时间
  DateTime? delete_time; //删除时间

  LikeModel({
    this.user_id = 0,
    this.up_type = 0,
    this.up_id = 0,
    this.create_time,
    this.delete_time,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      user_id: json['user_id'],
      up_type: json['up_type'],
      up_id: json['up_id'],
      create_time: json['create_time'],
      delete_time: json['delete_time'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id':user_id,
    'up_type':up_type,
    'up_id':up_id,
    'create_time':create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
    'delete_time':delete_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(delete_time!),
  };
}
