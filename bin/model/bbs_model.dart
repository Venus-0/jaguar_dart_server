import 'package:intl/intl.dart';

///文章 帖子 问题数据模型
class BBSModel {
  static const int TYPE_QUESTION = 1; //问题
  static const int TYPE_WIKI = 2; //文章
  static const int TYPE_POST = 3; //帖子
  static const List<int> TYPE_LIST = [TYPE_QUESTION, TYPE_WIKI, TYPE_POST];

  int id; //帖子id
  int user_id; //发帖人id
  String title; //标题
  String content; //正文
  int question_type; //类型 1问题 2文章帖子
  int reply_count; //回复数量
  int up_count; //点赞数量
  int is_recommand; //是否为推荐贴
  int is_top; //是否为加精贴
  DateTime? last_reply_time; //最后回复时间
  DateTime? create_time; //创建时间
  DateTime? delete_time; //删除时间
  DateTime? update_time; //更新时间

  BBSModel({
    this.id = 0,
    this.user_id = 0,
    this.title = '',
    this.content = '',
    this.question_type = 0,
    this.reply_count = 0,
    this.up_count = 0,
    this.is_recommand = 0,
    this.is_top = 0,
    this.last_reply_time,
    this.create_time,
    this.delete_time,
    this.update_time,
  });

  factory BBSModel.fromJson(Map<String, dynamic> json) {
    return BBSModel(
      id: json['id'],
      user_id: json['user_id'],
      title: json['title'],
      content: json['content'],
      question_type: json['question_type'],
      reply_count: json['reply_count'],
      up_count: json['up_count'],
      is_recommand: json['is_recommand'],
      is_top: json['is_top'],
      last_reply_time: json['last_reply_time'],
      create_time: json['create_time'],
      delete_time: json['delete_time'],
      update_time: json['update_time'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': user_id,
        'title': title,
        'content': content,
        'question_type': question_type,
        'reply_count': reply_count,
        'up_count': up_count,
        'is_recommand': is_recommand,
        'is_top': is_top,
        'last_reply_time': last_reply_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(last_reply_time!),
        'create_time': create_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(create_time!),
        'delete_time': delete_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(delete_time!),
        'update_time': update_time == null ? null : DateFormat("yyyy-MM-dd HH:mm:ss").format(update_time!),
      };
}
