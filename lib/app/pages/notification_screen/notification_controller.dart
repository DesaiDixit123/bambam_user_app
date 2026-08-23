import 'dart:convert';
import 'dart:developer' as dev;
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/domain.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  NotificationController(this.notificationPresenter);

  final NotificationPresenter notificationPresenter;

  List<NotificationModel> notifications = [];
  bool isLoading = false;
  bool _isFetching = false;

  @override
  void onInit() {
    super.onInit();
    getNotifications();
  }

  Future<void> getNotifications({bool isPullRefresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isPullRefresh) {
      isLoading = true;
      update();
    }

    try {
      final res = await notificationPresenter.getNotifications();
      if (!res.hasError) {
        final decoded = jsonDecode(res.data);
        if (decoded != null && decoded['Data'] != null) {
          final data = decoded['Data'];
          if (data is List) {
            notifications = NotificationModel.fromList(data);
          } else if (data is Map && data['formatted'] is List) {
            notifications = NotificationModel.fromList(data['formatted']);
          }
        }
      } else {
        // Handle error if needed
        Utility.showMessage(
          'Failed to load notifications',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e) {
      dev.log('Error fetching notifications: $e');
    } finally {
      isLoading = false;
      _isFetching = false;
      update();
    }
  }
}
