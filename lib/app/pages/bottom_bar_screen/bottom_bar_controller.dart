import 'dart:convert';

import 'package:bam_bam_user/app/pages/pages.dart';
import 'package:bam_bam_user/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_user/domain/repositories/repository.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class BottomBarController extends GetxController {
  BottomBarController(this.bottomBarPresenter);
  final BottomBarPresenter bottomBarPresenter;

  int currentIndex = 0;

  List<Widget> selectList = [
    HomeScreen(),
    BookingHistoryScreen(),
    ProfileScreen(),
  ];


  List <String> cityList = ["dds", "sd" , "sd"];

  String selectedCity = "dds" ; 


  final List<String> locations = [
  "Surat, Gujarat",
  "Mumbai, Maharashtra",
  "Delhi, Delhi",
  "Bengaluru, Karnataka",
  // Add more locations as needed
];

var currentLocation = "Surat, Gujarat".obs;

 void updateLocation(String newLocation) {
    currentLocation.value = newLocation;
  }

 void showLocationList(BuildContext context, List<String> locations) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300, // Adjust the height
          child: ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(locations[index]),
                onTap: () {
                  // Update the current location
                  currentLocation.value = locations[index];
                  Navigator.pop(context); // Close the bottom sheet
                },
              );
            },
          ),
        );
      },
    );
 }
 String userName = 'User';
  String userCity = 'Select City';

  @override
  void onInit() {
    super.onInit();
    _loadUserFromLocal();
    fetchUserLocation();

  }

 
  void _loadUserFromLocal() {
    try {
      final repo = Get.find<Repository>();
      final userJson = repo.getStringValue(LocalKeys.userDetails);
      if (userJson != null && userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          userName = (decoded['full_name'] ?? decoded['traveler_name'] ?? 'User').toString();
          // some APIs may save 'city' at top-level; try a couple of keys
         // userCity = (decoded['city'] ?? decoded['selected_city'] ?? decoded['zip_code'] ?? 'Select City').toString();
        }
      }
    } catch (e) {
      // ignore parse errors — keep defaults
      debugPrint('Error loading user from local: $e');
    }
    update();
  }
Future<void> fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        currentLocation.value = "Location disabled";
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          currentLocation.value = "Location permission denied";
          return;
        }
      }

      // Get device location 
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        userCity = placemarks.first.locality ?? "";
        currentLocation.value = userCity.isNotEmpty ? userCity : "Unknown city";
      } else {
        currentLocation.value = "City not found";
      }

      update();
    } catch (e) {
      currentLocation.value = "Unable to fetch location";
      update();
    }
  }

  // Call this if profile updates so bottom bar shows new values:
  void refreshUserInfo() {
    _loadUserFromLocal();
  }

  bool _isRefreshingLocation = false;

  /// Pull-to-refresh on home tab header area (location + user info).
  Future<void> refreshHomeTab() async {
    if (_isRefreshingLocation) return;
    _isRefreshingLocation = true;
    try {
      await fetchUserLocation();
      _loadUserFromLocal();
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().loadPopularRoutes();
      }
    } finally {
      _isRefreshingLocation = false;
      update();
    }
  }
}
