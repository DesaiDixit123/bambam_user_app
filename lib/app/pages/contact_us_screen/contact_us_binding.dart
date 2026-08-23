// lib/app/pages/contact_us_screen/contact_us_binding.dart
import 'package:get/get.dart';
import '../contact_us_screen/contact_us_controller.dart';
import '../contact_us_screen/contact_us_presenter.dart';

class ContactUsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ContactUsPresenter>(() => ContactUsPresenter());
    Get.lazyPut<ContactUsController>(() => ContactUsController(presenter: Get.find()));
  }
}
