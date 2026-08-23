import 'package:get/get.dart';
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/domain.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure any low-level deps (repositories/services) are already registered
    // e.g. Get.put(Repository());  // done at app startup elsewhere

    // Register usecase for Home
    if (!Get.isRegistered<HomeUsecases>()) {
      Get.lazyPut<HomeUsecases>(() => HomeUsecases(Get.find()));
    }

    // Register HomePresenter that depends on HomeUsecases
    if (!Get.isRegistered<HomePresenter>()) {
      Get.lazyPut<HomePresenter>(() => HomePresenter(Get.find<HomeUsecases>()));
    }

    // NOTE: BottomBarPresenter (and its usecases) should be registered
    // in BottomBarBinding (or another binding) — do NOT attempt to reuse it here
    // unless HomeController actually requires it as a different param.

    // Finally register the HomeController using the correct types
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut<HomeController>(
        () => HomeController( Get.find<HomePresenter>(),),
        fenix: true, // optional: recreate if removed from memory
      );
    }
  }
}
