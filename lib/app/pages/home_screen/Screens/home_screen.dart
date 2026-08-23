// import 'package:bam_bam_user/domain/usecases/home_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:bam_bam_user/app/app.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<HomeController>()) {
      Get.delete<HomeController>(force: true);
    }

    final homePresenter = Get.isRegistered<HomePresenter>()
        ? Get.find<HomePresenter>()
        : Get.find<HomePresenter>();

    final controller = Get.put(HomeController(homePresenter));

    return GetBuilder<HomeController>(
      init: controller,
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA), // Premium ultra-light grey bg
          body: PullToRefreshWrapper(
            onRefresh: () => controller.loadPopularRoutes(),
            child: ListView(
              physics: kPullToRefreshScrollPhysics,
              children: [
                Dimens.boxHeight10,
                
                // --- Premium Search Bar ---
                Padding(
                  padding: Dimens.edgeInsets20_00_20_00,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CustomTextFormField(
                      preIocns: true,
                      heightBtn: 54, // Taller, more premium feel
                      style: Styles.txtBlackColorW50016, // Stronger text
                      readOnly: true,
                      hintText: "Where are you going?".tr,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      onTap: () {
                        RouteManagement.gotoSerchScreen();
                      },
                      filled: true,
                      fillColor: Colors.white,
                      hintStyle: Styles.txtG7Colors40014.copyWith(fontSize: 15),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: SvgPicture.asset(AssetConstants.ic_Search, color: ColorsValue.appColor, height: 20),
                      ),
                    ),
                  ),
                ),
                Dimens.boxHeight25,

                // --- Dynamic Trending Routes (Replaces Static Promo Banners) ---
                Padding(
                  padding: Dimens.edgeInsets20_00_20_00,
                  child: Text(
                    "Trending Destinations",
                    style: Styles.txtBlackColorW70018.copyWith(fontSize: 19, letterSpacing: -0.3),
                  ),
                ),
                Dimens.boxHeight16,
                GetBuilder<HomeController>(
                  builder: (controller) {
                    if (controller.isLoadingRoutes) {
                      return const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (controller.popularRoutesDetailed.isEmpty) {
                      return const SizedBox();
                    }

                    // Define premium gradient combinations for the dynamic cards
                    final gradients = [
                      [const Color(0xFFFF9900), const Color(0xFFFF5500)], // Orange
                      [const Color(0xFF2980B9), const Color(0xFF2C3E50)], // Blue
                      [const Color(0xFF27AE60), const Color(0xFF2E86C1)], // Green-Blue
                      [const Color(0xFF8E44AD), const Color(0xFF3498DB)], // Purple-Blue
                    ];

                    return SizedBox(
                      height: 140, // Taller banner size
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: controller.popularRoutesDetailed.length,
                        itemBuilder: (context, index) {
                          final route = controller.popularRoutesDetailed[index];
                          final from = route["from"]?.toString() ?? "";
                          final to = route["to"]?.toString() ?? "";
                          final tripType = route["trip_type"]?.toString() ?? "Oneway";
                          
                          // Assign a dynamic gradient based on index
                          final colorCombo = gradients[index % gradients.length];
                          final color1 = colorCombo[0];
                          final color2 = colorCombo[1];

                          return GestureDetector(
                            onTap: () {
                              controller.onPopularRouteSelected(route);
                            },
                            child: Container(
                              width: 290,
                              margin: const EdgeInsets.only(right: 16, bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [color1, color2],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color2.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20,
                                    bottom: -20,
                                    child: Icon(
                                      Icons.directions_car, 
                                      size: 110, 
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                to,
                                                style: const TextStyle(
                                                  color: Colors.white, 
                                                  fontSize: 22, 
                                                  fontWeight: FontWeight.bold, 
                                                  letterSpacing: -0.5
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              "From $from",
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.9), 
                                                fontSize: 14, 
                                                fontWeight: FontWeight.w500
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                tripType,
                                                style: const TextStyle(
                                                  color: Colors.white, 
                                                  fontSize: 10, 
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                Dimens.boxHeight30,

                // --- REDESIGNED: Why Choose Us? ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: Dimens.edgeInsets20_00_20_00,
                        child: Text(
                          "Why Choose Bambam?",
                          style: Styles.txtBlackColorW70018.copyWith(fontSize: 19, letterSpacing: -0.3),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildWhyChooseCard("Wide Network Across India", "Travel anywhere seamlessly.", Icons.map),
                            const SizedBox(height: 12),
                            _buildWhyChooseCard("Luxury, Comfort, Freedom", "Top tier vehicles for your journey.", Icons.weekend),
                            const SizedBox(height: 12),
                            _buildWhyChooseCard("Transparent Pricing", "No hidden fees or surprise charges.", Icons.account_balance_wallet),
                            const SizedBox(height: 12),
                            _buildWhyChooseCard("24/7 Customer Support", "Always here to help you out.", Icons.support_agent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Dimens.boxHeight30,

                // --- Featured Services ---
                Padding(
                  padding: Dimens.edgeInsets20_00_20_00,
                  child: Text(
                    "Featured Services",
                    style: Styles.txtBlackColorW70018.copyWith(fontSize: 19, letterSpacing: -0.3),
                  ),
                ),
                Dimens.boxHeight16,
                Padding(
                  padding: Dimens.edgeInsets20_00_20_00,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _buildQuickActionCard("Local Rental", Icons.location_city, () {
                        controller.exploreFromQuickAction(2);
                      }),
                      _buildQuickActionCard("Airport", Icons.local_airport, () {
                        controller.exploreFromQuickAction(3);
                      }),
                      _buildQuickActionCard("One Way", Icons.arrow_right_alt, () {
                        controller.exploreFromQuickAction(0);
                      }),
                      _buildQuickActionCard("Round Trip", Icons.loop, () {
                        controller.exploreFromQuickAction(1);
                      }),
                    ],
                  ),
                ),

                Dimens.boxHeight40,
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper for Premium Horizontal "Why Choose Us" Cards
  Widget _buildWhyChooseCard(String title, String subtitle, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsValue.appColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ColorsValue.appColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Styles.txtBlackColorW70018.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Styles.txtG7Colors40014.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Featured Services Quick Actions
  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorsValue.appColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: ColorsValue.appColor,
                    size: 26,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Styles.txtBlackColorW40014.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
