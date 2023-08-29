import '../conf/config.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../model/mail_model.dart';

class MailSender {
  late String _userName;
  late String _password;

  MailSender() {
    _userName = Config.emailSenderConfig['userName'];
    _password = Config.emailSenderConfig['password'];
  }

  Future<bool> sendMail(MailModel mail) async {
    final smtpServer = qq(_password, _password);
    final message = Message()
      ..from = Address(_userName)
      ..recipients.add(mail.address)
      ..subject = mail.subject
      ..text = mail.text
      ..html = mail.html;

    try {
      final sendReport = await send(message, smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }
}
