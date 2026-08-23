// lib/app/pages/contact_us_screen/contact_us_model.dart
class ContactUsModel {
  final String name;
  final String email;
  final String mobile;
  final String subject;
  final String message;
  final String captcha;

  ContactUsModel({
    required this.name,
    required this.email,
    required this.mobile,
    required this.subject,
    required this.message,
    required this.captcha,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'mobile': mobile,
        'subject': subject,
        'message': message,
        'captcha': captcha,
      };
}
