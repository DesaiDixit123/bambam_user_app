// lib/app/pages/about_us_screen/about_us_presenter.dart
import '../../../data/helpers/api_wrapper.dart';
import '../../../data/models/about_us_model.dart';

class AboutUsPresenter {
  final ApiWrapper _api = ApiWrapper();

  Future<AboutUsModel> getAboutUs() async {
    // Assuming endpoint exists: /about-us
    final response = await _api.get('about-us');
    if (response.statusCode == 200) {
      return AboutUsModel.fromJson(response.data);
    } else {
      throw Exception('Failed to load About Us: ${response.statusCode}');
    }
  }
}
