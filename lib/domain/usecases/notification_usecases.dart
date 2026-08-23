import 'package:bam_bam_user/domain/domain.dart';

class NotificationUsecases {
  NotificationUsecases(this.repository);

  final Repository repository;

  Future<ResponseModel> getNotifications() async =>
      await repository.getNotifications();
}
