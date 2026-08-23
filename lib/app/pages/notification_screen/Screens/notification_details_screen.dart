import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationDetailsScreen extends StatelessWidget {
  const NotificationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notification = Get.arguments as NotificationModel?;

    if (notification == null) {
      return Scaffold(
        backgroundColor: ColorsValue.appBg,
        appBar: AppBarWidget(
          onTapBack: () => Get.back(),
          title: "Notification Details",
        ),
        body: const Center(
          child: Text("No notification details found"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorsValue.appBg,
      appBar: AppBarWidget(
        onTapBack: () => Get.back(),
        title: "Notification Details",
      ),
      body: SingleChildScrollView(
        key: ValueKey(notification.id),
        padding: Dimens.edgeInsets20,
        child: Container(
          width: double.maxFinite,
          padding: Dimens.edgeInsets20,
          decoration: BoxDecoration(
            color: ColorsValue.whiteColor,
            borderRadius: BorderRadius.circular(Dimens.sixteen),
            border: Border.all(color: ColorsValue.borderColors),
            boxShadow: [
              BoxShadow(
                color: ColorsValue.txtG7Color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimens.fifty),
                      border: Border.all(color: ColorsValue.borderColors),
                      color: ColorsValue.appColor.withValues(alpha: 0.1),
                    ),
                    child: Padding(
                      padding: Dimens.edgeInsets8,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: ColorsValue.appColor,
                        size: Dimens.twentyFour,
                      ),
                    ),
                  ),
                  Dimens.boxWidth15,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title ?? "Notification",
                          style: Styles.txtBlackColorW60016.copyWith(
                            fontSize: Dimens.eighteen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Dimens.boxHeight8,
                        Text(
                          notification.createdAt ?? "",
                          style: Styles.txtG7Colors40014.copyWith(
                            fontSize: Dimens.twelve,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 32, color: ColorsValue.borderColors),
              Text(
                notification.message ?? "",
                style: Styles.txtG5ColorsW40014.copyWith(
                  fontSize: Dimens.fourteen,
                  height: 1.5,
                ),
              ),
              if (notification.bookingRef != null &&
                  notification.bookingRef!.isNotEmpty) ...[
                Dimens.boxHeight20,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorsValue.appColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimens.six),
                  ),
                  child: Text(
                    "Booking Ref: ${notification.bookingRef}",
                    style: Styles.txtBlackColorW60016.copyWith(
                      fontSize: Dimens.fourteen,
                      color: ColorsValue.appColor,
                    ),
                  ),
                ),
              ],
              if (notification.bookingId != null &&
                  notification.bookingId!.isNotEmpty) ...[
                Dimens.boxHeight30,
                CustomButton(
                  onPressed: () {
                    Get.to(
                      () => const BookinghistoryDetilesScreen(),
                      arguments: {
                        "id": notification.bookingId,
                        "isCancel": false,
                        "isAgainBooking": false,
                        "isReview": false,
                      },
                    );
                  },
                  text: "View Booking",
                  backgroundColor: ColorsValue.appColor,
                  isColor: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
