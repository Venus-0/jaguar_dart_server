import '../conf/config.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../model/mail_model.dart';

class MailSender {
  late String _userName;
  late String authorization;

  MailSender() {
    _userName = Config.emailSenderConfig['userName'];
    authorization = Config.emailSenderConfig['authorization'];
  }

  Future<bool> sendMail(MailModel mail) async {
    final smtpServer = SmtpServer(
      'smtp.qq.com',
      ssl: true,
      port: 465,
      username: _userName,
      password: authorization,
    );
    final message = Message()
      ..from = Address(_userName)
      ..recipients.add(mail.address)
      ..subject = mail.subject
      ..text = mail.text
      ..html = mail.html;

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
