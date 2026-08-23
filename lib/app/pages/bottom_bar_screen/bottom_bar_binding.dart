import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/domain.dart';
import 'package:get/get.dart';

class BottomBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BottomBarController>(
      () => BottomBarController(
        Get.put(
          BottomBarPresenter(
            Get.put(BottomBarUsecases(Get.find()), permanent: true),
          ),
        ),
      ),
    );

    Get.put<HomeController>(
      HomeController(
        Get.put(
          HomePresenter(Get.put(HomeUsecases(Get.find()), permanent: true)),
        ),
       
       
      ),
    );
    Get.put<ProfileController>(
      ProfileController(
        Get.put(
          ProfilePresenter(
            Get.put(ProfileUsecases(Get.find()), permanent: true),
          ),
        ),
      ),
    );
    Get.put<BookingHistoryController>(
      BookingHistoryController(
        Get.put(
          BookingHistoryPresenter(
            Get.put(BookingHistoryUsecases(Get.find()), permanent: true),
          ),
        ),
      ),
    );
  }
}
