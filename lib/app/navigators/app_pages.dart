import 'package:get/get.dart';
import 'package:bam_bam_user/app/pages/pages.dart';


part 'app_routes.dart';

class AppPages {
  static var transitionDuration = const Duration(milliseconds: 300);

  static const initial = _Paths.splashScreen;
  static final pages = <GetPage>[
    GetPage<SplashScreen>(
      name: _Paths.splashScreen,
      transitionDuration: transitionDuration,
      page: SplashScreen.new,
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<InAppUpdateScreen>(
      name: _Paths.inAppUpdateScreen,
      transitionDuration: transitionDuration,
      page: InAppUpdateScreen.new,
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<HomeScreen>(
      name: _Paths.homeScreen,
      transitionDuration: transitionDuration,
      page: HomeScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<LoginScreen>(
      name: _Paths.loginScreen,
      transitionDuration: transitionDuration,
      page: LoginScreen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<GetStartScreen>(
      name: _Paths.getStartScreen,
      transitionDuration: transitionDuration,
      page: GetStartScreen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<Intro1Screen>(
      name: _Paths.intro1Screen,
      transitionDuration: transitionDuration,
      page: Intro1Screen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<Intro2Screen>(
      name: _Paths.intro2Screen,
      transitionDuration: transitionDuration,
      page: Intro2Screen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<OtpVerifyScreen>(
      name: _Paths.otpVerifyScreen,
      transitionDuration: transitionDuration,
      page: OtpVerifyScreen.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<ProfileScreen>(
      name: _Paths.profileScreen,
      transitionDuration: transitionDuration,
      page: ProfileScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<BookingHistoryScreen>(
      name: _Paths.bookingHistoryScreen,
      transitionDuration: transitionDuration,
      page: BookingHistoryScreen.new,
      binding: BookingHistoryBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<BottomBarScreen>(
      name: _Paths.bottomBarScreen,
      transitionDuration: transitionDuration,
      page: BottomBarScreen.new,
      binding: BottomBarBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<SelectVehicalScreen>(
      name: _Paths.selectVehicalScreen,
      transitionDuration: transitionDuration,
      page: SelectVehicalScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<VehicalDetilesScreen>(
      name: _Paths.vehicalDetilesScreen,
      transitionDuration: transitionDuration,
      page: VehicalDetilesScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<SerchScreen>(
      name: _Paths.serchScreen,
      transitionDuration: transitionDuration,
      page: SerchScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<CouponoffersScreen>(
      name: _Paths.couponoffersScreen,
      transitionDuration: transitionDuration,
      page: CouponoffersScreen.new,
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<BookinghistoryDetilesScreen>(
      name: _Paths.bookinghistoryDetilesScreen,
      transitionDuration: transitionDuration,
      page: BookinghistoryDetilesScreen.new,
      binding: BookingHistoryBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<PersonalDetilesScreen>(
      name: _Paths.personalDetilesScreen,
      transitionDuration: transitionDuration,
      page: PersonalDetilesScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<PrivcyPolicyScreen>(
      name: _Paths.privcyPolicyScreen,
      transitionDuration: transitionDuration,
      page: PrivcyPolicyScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<TermsConditionsScreen>(
      name: _Paths.termsConditionsScreen,
      transitionDuration: transitionDuration,
      page: TermsConditionsScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<MyTicketlistScreen>(
      name: _Paths.myTicketlistScreen,
      transitionDuration: transitionDuration,
      page: MyTicketlistScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<CreatTicketScreen>(
      name: _Paths.creatTicketScreen,
      transitionDuration: transitionDuration,
      page: CreatTicketScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<TicketDetilesScreen>(
      name: _Paths.ticketDetilesScreen,
      transitionDuration: transitionDuration,
      page: TicketDetilesScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<NotificationScreen>(
      name: _Paths.notificationScreen,
      transitionDuration: transitionDuration,
      page: NotificationScreen.new,
      binding: NotificationBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<NotificationDetailsScreen>(
      name: _Paths.notificationDetailsScreen,
      transitionDuration: transitionDuration,
      page: NotificationDetailsScreen.new,
      binding: NotificationBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<FaqScreen>(
      name: _Paths.faqScreen,
      transitionDuration: transitionDuration,
      page: FaqScreen.new,
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}
