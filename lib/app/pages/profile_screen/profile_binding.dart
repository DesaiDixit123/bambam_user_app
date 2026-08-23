import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/domain.dart';
import 'package:get/get.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        Get.put(
          ProfilePresenter(
            Get.put(ProfileUsecases(Get.find()), permanent: true),
          ),
        ),
      ),
    );
  }
}
