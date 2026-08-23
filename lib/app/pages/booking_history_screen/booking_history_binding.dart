import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/usecases/booking_history_usecases.dart';
import 'package:get/get.dart';

class BookingHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingHistoryController>(
      () => BookingHistoryController(
        Get.put(
          BookingHistoryPresenter(
            Get.put(BookingHistoryUsecases(Get.find()), permanent: true),
          ),
        ),
      ),
    );
  }
}
