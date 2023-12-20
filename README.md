# jaguar_dart_server

A server coded by Dart with jaguar.  

## 项目配置

> Dart SDK version 2.16.0  
> jaguar version 3.1.1

### 项目结构

#### [main.dart](./bin/main.dart) 项目入口

#### [server.dart](./bin/server.dart) - 服务初始化入口

#### [socket.dart](./bin/socket.dart) - socket入口

#### api目录 - 接口相关

##### [base_api.dart](./bin/api/base_api.dart) - 接口基类

##### [admin.dart](./bin/api/admin.dart) -管理员接口方法

##### [bbs.dart](./bin/api/bbs.dart) - 论坛接口方法

##### [common.dart](./bin/api/common.dart) - 公共接口方法

##### [message.dart](./bin/api/message.dart) - 私信接口方法

##### [user.dart](./bin/api/user.dart) - 用户接口方法

#### conf目录 - 配置相关

##### [config.dart](./bin/conf/config.dart) - 静态配置(数据库，token有效期，邮箱配置)

#### db目录 - 数据库相关

##### [bbs_dao.dart](./bin/db/bbs_dao.dart) - 论坛DAO方法

##### [comment_dao.dart](./bin/db/comment_dao.dart) - 评论DAO方法

##### [global_dao.dart](./bin/db/global_dao.dart) - 通用DAO方法

##### [image_dao.dart](./bin/db/image_dao.dart) - 图片DAO方法

##### [messgae_dao.dart](./bin/db/message_dao.dart) - 私信DAO方法

##### [mysql.dart](./bin/db/mysql.dart) - MySQL方法

##### [sessionDao.dart](./bin/db/sessionDao.dart) - tokenDAO方法

#### model目录 - 数据模型相关

##### [admin_user_model.dart](./bin/model/admin_user_model.dart) - 管理员用户类

##### [bbs_model.dart](./bin/model/bbs_model.dart) - 论坛类

##### [comment_model.dart](./bin/model/comment_model.dart) -评论类

##### [image_model.dart](./bin/model/image_model.dart) - 图片类

##### [like_model.dart](./bin/model/like_model.dart) - 点赞类

##### [mail_model.dart](./bin/model/mail_model.dart) - 邮件类

##### [message_model.dart](./bin/model/message_model.dart) - 消息类

##### [notice_model.dart](./bin/model/notice_model.dart) - 公告类

##### [response.dart](./bin/model/response.dart) - 返回数据类

##### [socket_data_model.dart](./bin/model/socket_data_model.dart) - socket数据类

##### [token_model.dart](./bin/model/token_model.dart) - token类

##### [user_model.dart](./bin/model/user_model.dart) - 用户类

#### utils目录 - 通用方法相关

##### [data_utils.dart](./bin/utils/data_utils.dart) - 数据处理方法

##### [mail_utils.dart](./bin/utils/mail_utils.dart) - 邮箱方法
