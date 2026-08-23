// lib/app/pages/about_us_screen/about_us_controller.dart
import 'package:get/get.dart';
import '../about_us_screen/about_us_presenter.dart';
import '../../../data/models/about_us_model.dart';

class AboutUsController extends GetxController {
  final AboutUsPresenter presenter;

  AboutUsController({required this.presenter});

  var isLoading = false.obs;
  var aboutUs = AboutUsModel.empty().obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAboutUs();
  }

  void fetchAboutUs() async {
    isLoading.value = true;
    try {
      final response = await presenter.getAboutUs();
      aboutUs.value = response;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
