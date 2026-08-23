// lib/app/pages/contact_us_screen/contact_us_presenter.dart
import '../../../data/helpers/api_wrapper.dart';
import '../../../data/models/contact_us_model.dart';

class ContactUsPresenter {
  final ApiWrapper _api = ApiWrapper();

  Future<void> submitContactUs(ContactUsModel model) async {
    final response = await _api.post('contact/create', data: model.toJson());
    if (response.statusCode != 200) {
      throw Exception('Failed to submit contact request: ${response.statusCode}');
    }
  }
}
