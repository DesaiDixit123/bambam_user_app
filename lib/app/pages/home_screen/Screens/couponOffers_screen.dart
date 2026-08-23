// couponoffers_screen.dart
import 'dart:convert';

import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CouponoffersScreen extends StatefulWidget {
  const CouponoffersScreen({super.key});

  @override
  State<CouponoffersScreen> createState() => _CouponoffersScreenState();
}

class _CouponoffersScreenState extends State<CouponoffersScreen> {
  final HomeController controller = Get.find<HomeController>();
  
  List<dynamic> offers = [];
  bool loading = true;
  String searchCode = '';

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }
  String formatOfferDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso);
    return DateFormat('dd MMM yyyy').format(dt); // Example: 17 Nov 2025
  } catch (_) {
    return iso;
  }
}

              
  Future<void> _loadOffers() async {
    setState(() {
      loading = true;
    });

    final vehicleId = controller.selectedVehicleWrapper?["vehicle_type"]['_id']?.toString() ??
        (controller.exploreVehicles.isNotEmpty
            ? controller.exploreVehicles.first['_id']?.toString() ?? ''
            : '');
        
    final from = controller.selectedExploreCab?['from']?.toString() ?? controller.formController.text;
    String to = '';
    final toRaw = controller.selectedExploreCab?['to'];
    if (toRaw is List && toRaw.isNotEmpty) {
      to = toRaw.first.toString();
    } else {
      to = controller.toController.text;
    }

    final res = await controller.homePresenter.getOffers(
      vehicleId: vehicleId,
      from: from ?? '',
      to: to ?? '',
      showLoader: false,
    );

    setState(() {
      loading = false;
    });

    if (res.hasError) {
      try {
        final parsed = jsonDecode(res.data);
        Utility.showMessage(parsed['Message']?.toString() ?? parsed['message']?.toString() ?? 'Failed to fetch offers', MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage('Failed to fetch offers', MessageType.error, null, 'OK');
      }
      return;
    }

    try {
      final json = jsonDecode(res.data) as Map<String, dynamic>;
      final data = json['Data'];
      if (data is List) {
        setState(() {
          offers = data;
        });
      } else if (data is Map && data.containsKey('Data')) {
        // some APIs wrap results differently
        offers = (data['Data'] as List<dynamic>?) ?? [];
      } else {
        offers = (json['Data'] as List<dynamic>?) ?? [];
      }
    } catch (e) {
      Utility.showMessage('Failed to parse offers', MessageType.error, null, 'OK');
    }
  }

  void _applyOffer(Map<String, dynamic> offer) {
    // Set selected offer in controller and recalc fare
   
    controller.selectedOffer = offer;
    final discountVal = (offer['discount_value'] ?? 0);
    controller.discountValue = (discountVal is num) ? discountVal.toDouble() : double.tryParse(discountVal.toString()) ?? 0.0;
    controller.updateTotalFare();
    controller.update();

    // close and return
   Navigator.pop(  context);
  }
  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (_) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Coupon & Offers",
          ),
          body: PullToRefreshWrapper(
            onRefresh: _loadOffers,
            child: loading
              ? ListView(
                    physics: kPullToRefreshScrollPhysics,
                    children: const [
                      SizedBox(height: 200),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
              : ListView(
                  physics: kPullToRefreshScrollPhysics,
                  padding: Dimens.edgeInsets20,
                  children: [
                    // search field (coupon code)
                    CustomTextFormField(
                      style: Styles.txtBlackColorW40014,
                      hintText: "Enter Coupon Code".tr,
                      filled: true,
                      isBorder: false,
                      textEditingController: TextEditingController(text: searchCode),
                      fillColor: ColorsValue.bulycolorsCB,
                      onChanged: (v) {
                        searchCode = v;
                      },
                      suffixIcon: TextButton(
                        onPressed: () {
                          // simple local filter by code; real apply should hit backend validate endpoint
                          final local = offers.firstWhereOrNull((o) => (o['offer_code']?.toString() ?? '').toLowerCase() == searchCode.trim().toLowerCase());
                          if (local != null) {
                            _applyOffer(local as Map<String, dynamic>);
                          } else {
                            Utility.showMessage('Invalid coupon code', MessageType.error, null, 'OK');
                          }
                        },
                        child: Text(
                          "Apply",
                          style: Styles.appColorw50014.copyWith(fontSize: Dimens.sixteen),
                        ),
                      ),
                      hintStyle: Styles.txtG7Colors40014,
                    ),
                    Dimens.boxHeight32,

                    if (offers.isEmpty) ...[
                      Center(child: Text("No offers available", style: Styles.txtG5ColorsW40014)),
                    ] else ...offers.map((o) {
  final offer = o as Map<String, dynamic>;
  final name = offer['offer_name'] ?? offer['offer_code'] ?? '';
  final code = offer['offer_code'] ?? '';
 final isApplied = controller.selectedOffer?['offer_code'] == code;

  // remove HTML tags from description
  final rawDesc = offer['description']?.toString() ?? '';
  final desc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '');

  final disc = offer['discount_value'] ?? 0;
  final discType = offer['discount_type'] ?? '%';

final start = formatOfferDate(offer['start_datetime']?.toString());
final end   = formatOfferDate(offer['end_datetime']?.toString());
  return Container(
    decoration: BoxDecoration(
      color: ColorsValue.coupanBG,
      borderRadius: BorderRadius.circular(Dimens.twelve),
    ),
    margin: EdgeInsets.only(bottom: Dimens.twenty),
    child: Padding(
      padding: Dimens.edgeInsets20_10_20_10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name.toString(), style: Styles.txtBlackColorW60016),
                TextButton(
                onPressed: isApplied ? null : () => _applyOffer(offer),
                child: Text(
                  isApplied ? "Applied" : "Apply",
                  style: isApplied
                      ? Styles.txtG5ColorsW40014
                      : Styles.appColorw50014.copyWith(fontSize: Dimens.sixteen),
                ),
              ),
            ],
          ),
          Dimens.boxHeight10,

          // cleaned description
          Text(desc, style: Styles.appColorw50014),

          Dimens.boxHeight20,
          Row(
            spacing: Dimens.ten,
            children: [
              Container(height: 5, width: 5, decoration: BoxDecoration(color: ColorsValue.txtG5Colors, shape: BoxShape.circle)),
              Text("Discount: $disc$discType", style: Styles.txtG5ColorsW40012),
            ],
          ),
          Dimens.boxHeight2,
          Row(
            spacing: Dimens.ten,
            children: [
              Container(height: 5, width: 5, decoration: BoxDecoration(color: ColorsValue.txtG5Colors, shape: BoxShape.circle)),


Text(
  "Valid: $start → $end",
  style: Styles.txtG5ColorsW40012,
)

            ],
          ),
        ],
      ),
    ),
  );
}).toList(),

                  ],
                ),
          ),
        );
      },
    );
  }
}
