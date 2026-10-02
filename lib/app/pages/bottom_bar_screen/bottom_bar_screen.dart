import 'package:bam_bam_user/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class BottomBarScreen extends StatelessWidget {
  const BottomBarScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    
    return GetBuilder<BottomBarController>(
      initState: (state) {},
      builder: (controller) {
        // final List<String>  = [
        //   "Surat, Gujarat",
        //   "Mumbai, Maharashtra",
        //   "Delhi, Delhi",
        //   "Bengaluru, Karnataka",
        // ];
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentIndex,
            backgroundColor: ColorsValue.whiteColor,
            elevation: Dimens.ten,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (value) {
              controller.currentIndex = value;
              controller.update();
            },
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: SvgPicture.asset(AssetConstants.ic_home),
                activeIcon: Container(
                  width: Dimens.sixtyFour,
                  height: Dimens.thirtyTwo,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(0xffFFF2DD),
                    borderRadius: BorderRadius.circular(Dimens.sixteen),
                  ),
                  child: SvgPicture.asset(AssetConstants.ic_fill_home),
                ),
                label: "",
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(AssetConstants.ic_history),
                activeIcon: Container(
                  width: Dimens.sixtyFour,
                  height: Dimens.thirtyTwo,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(0xffFFF2DD),
                    borderRadius: BorderRadius.circular(Dimens.sixteen),
                  ),
                  child: SvgPicture.asset(AssetConstants.ic_fill_history),
                ),
                label: "",
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(AssetConstants.ic_user1),
                activeIcon: Container(
                  width: Dimens.sixtyFour,
                  height: Dimens.thirtyTwo,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(0xffFFF2DD),
                    borderRadius: BorderRadius.circular(Dimens.sixteen),
                  ),
                  child: SvgPicture.asset(AssetConstants.ic_fill_user),
                ),
                label: "",
              ),
            ],
          ),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              Dimens.ninty * .77,
            ), // Adjust height as needed
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ColorsValue.appColor, ColorsValue.appColor],
                    ),
                    image: DecorationImage(
                      image: AssetImage(AssetConstants.appbar_BG),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // AppBar Content
                SafeArea(
                  child: Padding(
                    padding: Dimens.edgeInsets16_6_16_6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // inside SafeArea -> Padding -> Row -> children:
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      "Hello, ${controller.userName.isNotEmpty && controller.userName != 'User' ? controller.userName : 'User'} 🎉",
      style: Styles.whiteColorW50014,
    ),
    Dimens.boxHeight6,
                        InkWell(
                          onTap: () {
                            controller.checkAndFetchCurrentLocation(forcePrompt: true);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Obx(() => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: controller.isLocationDisabled
                                      ? Colors.orangeAccent
                                      : Colors.white,
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.55,
                                  ),
                                  child: Text(
                                    controller.isFetchingLocation
                                        ? "Detecting location..."
                                        : controller.isLocationDisabled
                                            ? "Location Disabled (Tap to enable)"
                                            : controller.currentLocation.value.isNotEmpty
                                                ? controller.currentLocation.value
                                                : "Choose Current Location",
                                    style: Styles.txtBlackColorW70020.copyWith(
                                      color: ColorsValue.whiteColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                              ],
                            )),
                          ),
                        ),
  ],
),

                      
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                RouteManagement.gotoNotificationScreen();
                              },
                              icon: SvgPicture.asset(
                                AssetConstants.ic_notification,
                              ),
                            ),


                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          body: controller.selectList[controller.currentIndex],
        );
      },
    );
  }
}
