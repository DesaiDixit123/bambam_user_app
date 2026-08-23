import 'package:bam_bam_user/app/pages/notification_screen/notification_controller.dart';
import 'package:bam_bam_user/app/pages/notification_screen/notification_presenter.dart';
import 'package:bam_bam_user/domain/domain.dart';
import 'package:get/get.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationController>(
      () => NotificationController(
        Get.put(
          NotificationPresenter(
            Get.put(NotificationUsecases(Get.find()), permanent: true),
          ),
        ),
      ),
    );
  }
}
