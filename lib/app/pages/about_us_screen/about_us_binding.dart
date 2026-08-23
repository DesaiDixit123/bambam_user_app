// lib/app/pages/about_us_screen/about_us_binding.dart
import 'package:get/get.dart';
import '../about_us_screen/about_us_controller.dart';
import '../about_us_screen/about_us_presenter.dart';

class AboutUsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AboutUsPresenter>(() => AboutUsPresenter());
    Get.lazyPut<AboutUsController>(() => AboutUsController(presenter: Get.find()));
  }
}
