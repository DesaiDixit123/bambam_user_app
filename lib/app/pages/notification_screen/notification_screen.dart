import 'package:bam_bam_user/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Notifications",
          ),
          body: PullToRefreshWrapper(
            onRefresh: () => controller.getNotifications(isPullRefresh: true),
            child: controller.isLoading
                ? ListView(
                      physics: kPullToRefreshScrollPhysics,
                      children: const [
                        SizedBox(height: 200),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                : controller.notifications.isEmpty
                ? ListView(
                      physics: kPullToRefreshScrollPhysics,
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_outlined,
                                size: Dimens.hundred,
                                color: ColorsValue.txtG7Color.withValues(alpha: 0.5),
                              ),
                              Dimens.boxHeight20,
                              Text(
                                "No notifications yet",
                                style: Styles.txtG7Colors40014,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                : ListView.separated(
                  physics: kPullToRefreshScrollPhysics,
                  itemCount: controller.notifications.length,
                  padding: Dimens.edgeInsets20,
                  separatorBuilder: (context, index) =>
                      Divider(height: 32, color: ColorsValue.borderColors),
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        RouteManagement.gotoNotificationDetailsScreen(notification);
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimens.fifty),
                              border: Border.all(color: ColorsValue.borderColors),
                              color: notification.isRead == false
                                  ? ColorsValue.appColor.withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: Padding(
                              padding: Dimens.edgeInsets8,
                              child: Icon(
                                Icons.notifications_outlined,
                                color: ColorsValue.appColor,
                                size: Dimens.twenty,
                              ),
                            ),
                          ),
                          Dimens.boxWidth15,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title ?? "Notification",
                                        style: Styles.txtBlackColorW40014
                                            .copyWith(
                                              fontWeight:
                                                  notification.isRead == false
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(notification.createdAt),
                                      style: Styles.txtG7Colors40014.copyWith(
                                        fontSize: Dimens.twelve,
                                      ),
                                    ),
                                  ],
                                ),
                                Dimens.boxHeight4,
                                Text(
                                  notification.message ?? "",
                                  style: Styles.txtG5ColorsW40014,
                                ),
                                if (notification.bookingRef != null &&
                                    notification.bookingRef!.isNotEmpty) ...[
                                  Dimens.boxHeight8,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColorsValue.appColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(Dimens.four),
                                    ),
                                    child: Text(
                                      "Booking Ref: ${notification.bookingRef}",
                                      style: Styles.txtBlackColorW60016.copyWith(
                                        fontSize: Dimens.twelve,
                                        color: ColorsValue.appColor,
                                      ),
                                    ),
                                  ),
                                ],
                                if (notification.bookingId != null &&
                                    notification.bookingId!.isNotEmpty) ...[
                                  Dimens.boxHeight10,
                                  InkWell(
                                    onTap: () {
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
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorsValue.appColor,
                                        borderRadius: BorderRadius.circular(Dimens.six),
                                      ),
                                      child: Text(
                                        "View Booking",
                                        style: Styles.txtBlackColorW60016.copyWith(
                                          fontSize: Dimens.twelve,
                                          color: ColorsValue.whiteColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return "${difference.inMinutes}m ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}h ago";
      } else if (difference.inDays < 7) {
        return "${difference.inDays}d ago";
      } else {
        return Utility.getFormatedTime(dateStr, "dd MMM, yyyy");
      }
    } catch (e) {
      return dateStr;
    }
  }
}
