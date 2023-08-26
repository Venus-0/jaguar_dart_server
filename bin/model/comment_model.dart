import 'package:intl/intl.dart';

///评论数据模型
class CommentModel {
  static const int TYPE_BBS = 1; //帖子文章
  static const int TYPE_QUESTION = 2; //问题评论（回答）
  static const int TYPE_COMMENT = 4; //楼中楼

  int id; //评论id
  int comment_type; //评论类型 1帖子文章 2问题 3回答 4楼中楼
  int comment_id; //评论对应帖子id
  int? sub_comment_id; //楼中楼对应id
  int user_id; //评论用户id
  String comment; //评论正文
  int up_count; //点赞数
  DateTime? create_time; //创建时间
  DateTime? update_time; //更新时间
  DateTime? delete_time; //删除时间

  CommentModel({
    this.id = 0,
    this.comment_type = 0,
    this.comment_id = 0,
    this.sub_comment_id,
    this.user_id = 0,
    this.comment = '',
    this.up_count = 0,
    this.create_time,
    this.delete_time,
    this.update_time,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      comment_type: json['comment_type'],
      comment_id: json['comment_id'],
      sub_comment_id: json['sub_comment_id'],
      user_id: json['user_id'],
      comment: json['comment'],
      up_count: json['up_count'],
      create_time: json['create_time'],
      delete_time: json['delete_time'],
      update_time: json['update_time'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'comment_type': comment_type,
        'comment_id': comment_id,
        'sub_comment_id': sub_comment_id,
        'user_id': user_id,
        'comment': comment,
        'up_count': up_count,
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd").format(create_time!),
        'delete_time': delete_time == null ? null : DateFormat("yyyy-MM-dd").format(delete_time!),
        'update_time': update_time == null ? null : DateFormat("yyyy-MM-dd").format(update_time!),
      };
}
