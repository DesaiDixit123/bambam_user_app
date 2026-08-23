import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/widgets/droup_down_widgets.dart';
import 'package:bam_bam_user/data/helpers/api_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final controller = Get.find<BookingHistoryController>() ;
  @override
  void initState() {
    super.initState();
     // ✅ Schedule fetch after first frame to avoid calling update() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchBookings();
    });
  }

Widget _buildBookingCard({
  required BuildContext context,
  required Map<String, dynamic> booking,
  required BookingHistoryController controller,
  required String badgeAsset,
  required String badgeText,
  required Color badgeTextColor,
}) {
   // -------------------------------
  // DATA EXTRACTION (SAFE)
  // -------------------------------
  final travel = controller.travelDetailsFor(booking) ?? {};
  final travell = controller.travelDetailssFor(booking) ?? {};
  final vehicle = controller.vehicleFor(booking) ?? {};

  final bookingId = (booking['booking_id'] ?? booking['_id'] ?? '—').toString();

  final tripType = (travel['trip_type'] ?? 'Oneway').toString();
  final from = (travell['from'] ?? travel['from'] ?? travel['city'] ?? '').toString();

  // -------------------------------
  // TO DESTINATION (SAFE)
  // -------------------------------
  String to = '';
  final toRaw = travel['to'];

  if (toRaw is List) {
    to = toRaw.whereType<String>().join('→');
  } else if (toRaw is String) {
    to = toRaw;
  }

  // -------------------------------
  // DATE (SAFE)
  // -------------------------------
  String dateText = '';
  final dtRaw = travell['date'] ?? booking['createdAt'];

  if (dtRaw is String && dtRaw.isNotEmpty) {
    try {
      dateText = DateFormat('dd-MM-yyyy').format(DateTime.parse(dtRaw));
    } catch (_) {
      dateText = dtRaw; // fallback
    }
  }

  // -------------------------------
  // RETURN DATE (SAFE)
  // -------------------------------
  String returnDateText = '';
  final returnDtRaw = travel['return_date'] ?? travell['return_date'];

  if (returnDtRaw is String && returnDtRaw.isNotEmpty) {
    try {
      returnDateText = DateFormat('dd-MM-yyyy').format(DateTime.parse(returnDtRaw.split("T").first));
    } catch (_) {
      returnDateText = returnDtRaw.split("T").first; // fallback
    }
  }

  // -------------------------------
  // TIME
  // -------------------------------
  final timeText = (travel['pickup_time'] ?? '').toString();

  // -------------------------------
  // IMAGE (SAFE)
  // -------------------------------
  String? carPhotoUrl;
  final vType = vehicle["vehicle_type"];

  if (vType is Map && vType['vehicle_photo'] != null) {
    carPhotoUrl = vType['vehicle_photo'].toString();
  }

  // -------------------------------
  // PRICE (SAFE)
  // -------------------------------
  final totalPayment = booking['total_payment'];


  // -------------------------------
  // STATUS BADGE
  // -------------------------------
  final status = (booking['booking_status'] ?? '').toString();
  final statusLower = status.toLowerCase();

  String displayStatus = 'Booking Complete';
  Color displayColor = Colors.green;
  IconData displayIcon = Icons.check_circle;
  
  if (statusLower == "confirmed") {
    displayStatus = "Booking Confirmed";
    displayColor = const Color(0xFFFF5A00); // #ff5a00
    displayIcon = Icons.local_taxi;
  } else if (statusLower == "pending") {
    displayStatus = "Booking Pending";
    displayColor = const Color(0xFFF59E0B); // #F59E0B
    displayIcon = Icons.schedule;
  } else if (statusLower == "cancelled") {
    displayStatus = "Booking Cancelled";
    displayColor = const Color(0xFFFF3B30); // #FF3B30
    displayIcon = Icons.cancel;
  } else if (statusLower == "expired") {
    displayStatus = "Booking Expired";
    displayColor = const Color(0xFFFF3B30); // #FF3B30
    displayIcon = Icons.cancel;
  } else if (statusLower == "d & v allocated" || statusLower.contains("alloc")) {
    displayStatus = "Driver & Vehicle Allocated";
    displayColor = const Color(0xFF00C0E8); // #00C0E8
    displayIcon = Icons.local_taxi;
  } else if (statusLower.contains("complete")) {
    displayStatus = "Booking Completed";
    displayColor = const Color(0xFF12724A); // #12724A
    displayIcon = Icons.check_circle;
  } else {
    displayStatus = status;
    displayColor = ColorsValue.appColor;
    displayIcon = Icons.local_taxi;
  }

  Widget statusBadge = Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: displayColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: displayColor, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(displayIcon, color: displayColor, size: 16),
        const SizedBox(width: 6),
        Text(
          displayStatus,
          style: Styles.txtBlackColorW60016.copyWith(color: displayColor, fontSize: 14),
        ),
      ],
    ),
  );

  return Column(
    children: [
      InkWell(
        borderRadius: BorderRadius.circular(Dimens.twenty),
        onTap: () => controller.onTapViewDetails(booking),
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.2),
                blurRadius: 5,
                spreadRadius: 1,
                offset: Offset(2, 4),
              )
            ],
            color: ColorsValue.bulycolorsCB,
            borderRadius: BorderRadius.circular(Dimens.twenty),
          ),
          child: Padding(
            padding: Dimens.edgeInsets20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Booking ID + Status Badge (Restructured to keep ID on single line and move badge down on the right)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookingId,
                      style: Styles.txtBlackColorW50018,
                    ),
                    Dimens.boxHeight4,
                    Align(
                      alignment: Alignment.centerRight,
                      child: statusBadge,
                    ),
                  ],
                ),

                Dimens.boxHeight12,

                // 🔹 Vehicle info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicle?['brand_name']?.toString() ?? 'Vehicle',
                            style: Styles.txtBlackColorW40014),
                        Text(
                            vehicle?['vehicle_type'] is Map
                                ? (vehicle!['vehicle_type']['name'] ?? '')
                                : (vehicle?['vehicle_type']?.toString() ??
                                    tripType),
                            style: Styles.txtG7Colors40014),
                      ],
                    ),
                    carPhotoUrl != null
                        ? Image.network(
                            carPhotoUrl,
                            height: Dimens.eighty,
                            width: Dimens.eighty,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                                AssetConstants.CarImge,
                                height: Dimens.eighty,
                                width: Dimens.hundredEighty),
                          )
                        : Image.asset(AssetConstants.CarImge,
                            height: Dimens.eighty,
                            width: Dimens.hundredEighty),
                  ],
                ),

                Dimens.boxHeight8,
                Container(height: 1, color: ColorsValue.borderColors),
                Dimens.boxHeight8,

                // 🔹 Route
                Text(tripType, style: Styles.txtG7Colors40014),
                Text(tripType.toLowerCase().contains("local") ? from : "$from → $to", style: Styles.txtBlackColorW40014),

                Dimens.boxHeight10,

                // 🔹 Date, Time, Amount (Restructured to show return date for Round Trips and always use clock for time)
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          // Pickup Date
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: ColorsValue.appColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateText.isNotEmpty ? dateText : '-',
                                style: Styles.txtG5ColorsW40014.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                          // Return Date (if Round Trip)
                          if ((tripType.toLowerCase().contains("round") || tripType.toLowerCase().contains("return")) &&
                              returnDateText.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  color: ColorsValue.appColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  returnDateText,
                                  style: Styles.txtG5ColorsW40014.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          // Pickup Time
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                AssetConstants.ic_clcok,
                                color: ColorsValue.appColor,
                                height: 18,
                                width: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                timeText.isNotEmpty ? timeText : '-',
                                style: Styles.txtG5ColorsW40014.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${totalPayment is num ? totalPayment.toStringAsFixed(0) : totalPayment}',
                      style: Styles.txtBlackColorW40014,
                    ),
                  ],
                ),

                Dimens.boxHeight16,

                // 🔹 Action buttons (view, cancel, etc.)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: Dimens.sixteen,
                  children: _buildActionButtons(context, controller, booking),
                ),
              ],
            ),
          ),
        ),
      ),
      Dimens.boxHeight15,
    ],
  );
}

  List<Widget> _buildActionButtons(BuildContext context, BookingHistoryController controller, Map<String, dynamic> booking) {
    final status = (booking['booking_status'] ?? '').toString().toLowerCase();
    if (status.contains('cancel') || status.contains('expire')) {
      // cancelled: Book again / View details
      return [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {  RouteManagement.gotoSerchScreen();},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Text("book_agin".tr, style: Styles.txtRedColorW50014.copyWith(color: ColorsValue.txtRedColor)),
                Positioned(bottom: 0, child: Container(height: 1, width: Dimens.hundredFiftyOne, color: ColorsValue.txtRedColor)),
              ],
            ),
          ),
        ),
        GestureDetector(
         behavior: HitTestBehavior.opaque,
         onTap: () => Get.to(
    () => BookinghistoryDetilesScreen(),
    arguments: {
      "id": booking["_id"],
      "isCancel": false,
      "isAgainBooking": false,
      "isReview": true,
    },),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Text("view_detiles".tr, style: Styles.txtRedColorW50014.copyWith(color: ColorsValue.appColor)),
                Positioned(bottom: 0, child: Container(height: 1, width: Dimens.hundredFiftyOne, color: ColorsValue.appColor)),
              ],
            ),
          ),
        ),
      ];
    } else if (status.contains('complete') || status.contains('completed')) {
      // completed: Write review / View details
      return [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>Get.to(
    () => BookinghistoryDetilesScreen(),
    arguments: {
      "id": booking["_id"],
      "isCancel": false,
      "isAgainBooking": false,
      "isReview": false,
    },),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Text("write_review".tr, style: Styles.txtRedColorW50014.copyWith(color: ColorsValue.appColor)),
                Positioned(bottom: 0, child: Container(height: 1, width: Dimens.hundredFiftyOne, color: ColorsValue.appColor)),
              ],
            ),
          ),
        ),
        GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Get.to(
    () => BookinghistoryDetilesScreen(),
    arguments: {
      "id": booking["_id"],
      "isCancel": false,
      "isAgainBooking": false,
      "isReview": true,
    },),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Text("view_detiles".tr, style: Styles.txtRedColorW50014.copyWith(color: ColorsValue.appColor)),
                Positioned(bottom: 0, child: Container(height: 1, width: Dimens.hundredFiftyOne, color: ColorsValue.appColor)),
              ],
            ),
          ),
        ),
      ];
    } else {
      // confirmed / in-progress: Cancel / View details
      return [
        GestureDetector(
           behavior: HitTestBehavior.opaque,
           onTap: () => controller.showBokigCancelDelog(context, customBookingId: booking["_id"]),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Text("cancel_booking".tr, style: Styles.txtRedColorW50014.copyWith(color: ColorsValue.txtRedColor)),
                Positioned(bottom: 0, child: Container(height: 1, width: Dimens.hundredFiftyOne, color: ColorsValue.txtRedColor)),
              ],
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Get.to(
    () => BookinghistoryDetilesScreen(),
    arguments: {
      "id": booking["_id"],
      "isCancel": false,
      "isAgainBooking": false,
      "isReview": false,
    },),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Text("view_detiles".tr, style: Styles.txtRedColorW50014.copyWith(color: ColorsValue.appColor)),
                Positioned(bottom: 0, child: Container(height: 1, width: Dimens.hundredFiftyOne, color: ColorsValue.appColor)),
              ],
            ),
          ),
        ),
      ];
    }
  }

  Widget _buildStatusTabBar(BookingHistoryController controller) {
    final List<String> statusTabs = [
      "Completed",
      "Pending",
      "Confirmed",
      "D & V Allocated",
      "Cancelled",
      "Expired",
      "All",
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: statusTabs.length,
        itemBuilder: (context, index) {
          final tab = statusTabs[index];
          final isSelected = controller.selectedStatus.toLowerCase() == tab.toLowerCase() ||
              (controller.selectedStatus.isEmpty && tab == "Completed");
          final count = controller.getStatusCount(tab);

          return GestureDetector(
            onTap: () {
              controller.onStatusChanged(tab);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFF5A00), Color(0xFFFF8800)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFEDF2F9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF5A00).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.25)
                          : const Color(0xFFCBD5E1).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$count",
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookingHistoryController>(
      builder: (controller) {
        return WillPopScope(
          onWillPop: () async {
            RouteManagement.gotoBottomBarScreen();
            return false;
          },
          child: Scaffold(
            backgroundColor: ColorsValue.appBg,
            appBar: AppBarWidget(onTapBack: () => RouteManagement.gotoBottomBarScreen(), title: "Booking History"),
            body: SafeArea(
              child: PullToRefreshWrapper(
                onRefresh: () => controller.fetchBookings(showLoader: false),
                child: ListView(
                  physics: kPullToRefreshScrollPhysics,
                  padding: Dimens.edgeInsets20,
                  children: [
                    CustomTextFormField(
                      preIocns: true,
                      heightBtn: Dimens.fourtySix,
                      style: Styles.txtBlackColorW40014,
                      readOnly: false,
                      hintText: "search".tr,
                      onChanged: (value) => controller.onSearchChanged(value),
                      filled: true,
                      fillColor: const Color(0xffEDF2F9),
                      hintStyle: Styles.txtG7Colors40014,
                      prefixIcon: SvgPicture.asset(AssetConstants.ic_Search),
                    ),
                    Dimens.boxHeight16,
                    
                    // 🎨 Modern Horizontal Status Tabs (Completed, Payment Pending, Pending, Confirmed, D & V Allocated, Cancelled, Expired, All)
                    _buildStatusTabBar(controller),

                    Dimens.boxHeight24,
                    Text(
                      "Today, ${DateFormat('dd MMM, yyyy').format(DateTime.now())}",
                      style: Styles.txtBlackColorW70018,
                      textAlign: TextAlign.start,
                    ),
                    Dimens.boxHeight16,
          
                    if (controller.isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80, bottom: 80),
                          child: CircularProgressIndicator(
                            color: ColorsValue.appColor,
                          ),
                        ),
                      )
                    else if (controller.error != null)
                      Column(
                        children: [
                          Text(controller.error!, style: Styles.txtRedColorW50014),
                          Dimens.boxHeight12,
                          CustomButton(
                            backgroundColor: ColorsValue.appColor,
                            isboxsedo: true,
                            onPressed: () => controller.fetchBookings(),
                            text: "Retry",
                            textStyle: Styles.txtBlackColorW40014,
                          )
                        ],
                      )
                    else ...[
                      if (controller.bookings.isNotEmpty) ...[
                        ...controller.bookings.map((b) => _buildBookingCard(
                              context: context,
                              booking: b,
                              controller: controller,
                              badgeAsset: AssetConstants.Green_CN,
                              badgeText: "booking",
                              badgeTextColor: ColorsValue.appColor,
                            )),
                      ],
                      if (controller.bookings.isEmpty)
                        Center(child: Padding(padding: const EdgeInsets.only(top: 60), child: Text("No bookings found".tr))),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
