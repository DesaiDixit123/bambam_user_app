import 'package:bam_bam_user/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'wallet_controller.dart';
import 'package:bam_bam_user/app/utils/utils.dart';
import 'package:bam_bam_user/app/navigators/routes_management.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            title: "Wallet".tr,
            onTapBack: () => Get.back(),
          ),
          body: Center(
            child: Text(
              "Wallet functionality coming soon...",
              style: Styles.txtBlackColorW50018,
            ),
          ),
        );
      },
    );
  }
}
