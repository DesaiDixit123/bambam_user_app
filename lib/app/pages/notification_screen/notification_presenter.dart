import 'package:bam_bam_user/domain/domain.dart';

class NotificationPresenter {
  NotificationPresenter(this.notificationUsecases);

  final NotificationUsecases notificationUsecases;

  Future<ResponseModel> getNotifications() async =>
      await notificationUsecases.getNotifications();
}
