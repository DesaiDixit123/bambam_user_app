import 'dart:convert';
import 'dart:developer';

import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/pages/pages.dart';
import 'package:bam_bam_user/data/helpers/api_wrapper.dart';
import 'package:bam_bam_user/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_user/domain/repositories/repository.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class BottomBarController extends GetxController with WidgetsBindingObserver {
  BottomBarController(this.bottomBarPresenter);
  final BottomBarPresenter bottomBarPresenter;

  int currentIndex = 0;

  List<Widget> selectList = [
    HomeScreen(),
    BookingHistoryScreen(),
    ProfileScreen(),
  ];

  List<String> cityList = ["dds", "sd", "sd"];
  String selectedCity = "dds";

  final List<String> locations = [
    "Surat, Gujarat",
    "Mumbai, Maharashtra",
    "Delhi, Delhi",
    "Bengaluru, Karnataka",
  ];

  var currentLocation = "Detecting location...".obs;
  String currentFullAddress = "";
  double? currentLat;
  double? currentLng;
  bool isFetchingLocation = false;
  bool isLocationDisabled = false;

  void updateLocation(String newLocation) {
    currentLocation.value = newLocation;
  }

  void showLocationList(BuildContext context, List<String> locations) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(locations[index]),
                onTap: () {
                  currentLocation.value = locations[index];
                  Navigator.pop(context);
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

    Future.microtask(() async {
      try {
        if (Get.isRegistered<ProfileController>()) {
          await Get.find<ProfileController>().fetchProfile(showLoader: false);
          _loadUserFromLocal();
        }
      } catch (_) {}
    });

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndFetchCurrentLocation(showPopupIfDisabled: true);
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (isLocationDisabled ||
          currentLocation.value.isEmpty ||
          currentLocation.value.contains("Disabled") ||
          currentLocation.value.contains("Denied")) {
        checkAndFetchCurrentLocation(showPopupIfDisabled: false);
      }
    }
  }

  void refreshUserDetails() {
    _loadUserFromLocal();
  }

  void _loadUserFromLocal() {
    try {
      final repo = Get.find<Repository>();
      final userJson = repo.getStringValue(LocalKeys.userDetails);
      if (userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          final name = (decoded['full_name'] ?? decoded['traveler_name'] ?? decoded['name'])?.toString().trim();
          if (name != null && name.isNotEmpty && name != 'null' && name != 'User') {
            userName = name;
          }
        }
      }
      if ((userName == 'User' || userName.isEmpty) && Get.isRegistered<ProfileController>()) {
        final profCtrl = Get.find<ProfileController>();
        final name = profCtrl.fullNameController.text.trim();
        if (name.isNotEmpty) {
          userName = name;
        }
      }
    } catch (e) {
      debugPrint('Error loading user from local: $e');
    }
    update();
  }

  /// Check GPS status, permission, and fetch current coordinates + reverse geocode
  Future<void> checkAndFetchCurrentLocation({
    bool showPopupIfDisabled = true,
    bool forcePrompt = false,
  }) async {
    try {
      isFetchingLocation = true;
      update();

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLocationDisabled = true;
        isFetchingLocation = false;
        currentLocation.value = "Location Disabled (Tap to enable)";
        update();
        if (showPopupIfDisabled || forcePrompt) {
          showLocationOffDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        isLocationDisabled = true;
        isFetchingLocation = false;
        currentLocation.value = "Permission Denied (Tap to grant)";
        update();
        if (showPopupIfDisabled || forcePrompt) {
          showLocationPermissionDialog(isPermanentlyDenied: false);
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        isLocationDisabled = true;
        isFetchingLocation = false;
        currentLocation.value = "Permission Denied (Tap to grant)";
        update();
        if (showPopupIfDisabled || forcePrompt) {
          showLocationPermissionDialog(isPermanentlyDenied: true);
        }
        return;
      }

      // If we reach here, location service is enabled and permission is granted!
      isLocationDisabled = false;
      update();

      // Dismiss dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      currentLat = position.latitude;
      currentLng = position.longitude;

      // 1️⃣ Direct Google Maps Geocoding API on UI side
      try {
        final googleUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${StringConstants.gpooglePlaceKey}',
        );
        final gResponse = await ApiWrapper.client
            .get(googleUrl)
            .timeout(const Duration(seconds: 8));

        if (gResponse.statusCode == 200 && gResponse.body.isNotEmpty) {
          final resData = jsonDecode(gResponse.body);
          if (resData['status'] == 'OK' &&
              resData['results'] is List &&
              (resData['results'] as List).isNotEmpty) {
            final firstResult = resData['results'][0];
            final comps = firstResult['address_components'] as List? ?? [];

            String getComp(List<String> types) {
              final found = comps.firstWhereOrNull(
                (c) =>
                    c is Map &&
                    (c['types'] as List?)?.any((t) => types.contains(t)) == true,
              );
              return found != null ? (found['long_name']?.toString() ?? '') : '';
            }

            final sublocality1 = getComp(['sublocality_level_1']);
            final sublocality2 = getComp(['sublocality_level_2']);
            final sublocality = getComp(['sublocality']);
            final neighborhood = getComp(['neighborhood']);
            final route = getComp(['route']);

            final area = [sublocality1, sublocality2, sublocality, neighborhood, route]
                .firstWhere((s) => s.isNotEmpty, orElse: () => '');
            final city = getComp(['locality']).isNotEmpty
                ? getComp(['locality'])
                : getComp(['administrative_area_level_2']);
            final formatted = firstResult['formatted_address']?.toString() ?? '';

            currentFullAddress = formatted;

            if (area.isNotEmpty && city.isNotEmpty) {
              if (!area.toLowerCase().contains(city.toLowerCase())) {
                currentLocation.value = "$area, $city";
              } else {
                currentLocation.value = area;
              }
            } else if (area.isNotEmpty) {
              currentLocation.value = area;
            } else if (city.isNotEmpty) {
              currentLocation.value = city;
            } else if (formatted.isNotEmpty) {
              final parts = formatted.split(',');
              currentLocation.value = parts.isNotEmpty ? parts[0].trim() : formatted;
            }

            if (city.isNotEmpty) {
              userCity = city;
            }
            update();
            return;
          }
        }
      } catch (gErr) {
        log("Direct Google Geocoding UI error: $gErr");
      }

      // 2️⃣ Fallback: Reverse geocode via backend API
      try {
        final uri = Uri.parse('${ApiWrapper.baseUrl}reverse-geocode');
        final body = jsonEncode({
          'lat': position.latitude,
          'lng': position.longitude,
        });

        final response = await ApiWrapper.client
            .post(
              uri,
              body: body,
              headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final resData = jsonDecode(response.body);
          if (resData is Map && resData.containsKey('Data') && resData['Data'] != null) {
            final data = resData['Data'];
            final formatted = data['formatted_address']?.toString() ?? "";
            final area = data['area']?.toString().trim() ?? "";
            final city = data['city']?.toString().trim() ?? "";
            currentFullAddress = formatted;

            if (area.isNotEmpty) {
              if (city.isNotEmpty && !area.toLowerCase().contains(city.toLowerCase())) {
                currentLocation.value = "$area, $city";
              } else {
                currentLocation.value = area;
              }
            } else if (formatted.isNotEmpty) {
              final parts = formatted.split(',');
              if (parts.isNotEmpty) {
                final firstPart = parts[0].trim();
                if (city.isNotEmpty && !firstPart.toLowerCase().contains(city.toLowerCase())) {
                  currentLocation.value = "$firstPart, $city";
                } else if (parts.length >= 2) {
                  currentLocation.value = "${parts[0].trim()}, ${parts[1].trim()}";
                } else {
                  currentLocation.value = firstPart;
                }
              } else {
                currentLocation.value = city.isNotEmpty ? city : formatted;
              }
            } else if (city.isNotEmpty) {
              currentLocation.value = city;
            } else {
              currentLocation.value = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
            }

            if (city.isNotEmpty) {
              userCity = city;
            }
            update();
            return;
          }
        }
      } catch (apiErr) {
        log("Backend reverse-geocode failed, falling back to local geocoding: $apiErr");
      }

      // Fallback: Placemark from coordinates
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark p = placemarks.first;
          final String area = p.subLocality ?? p.thoroughfare ?? "";
          final String city = p.locality ?? p.subAdministrativeArea ?? "";
          if (area.isNotEmpty && city.isNotEmpty) {
            currentLocation.value = "$area, $city";
          } else if (city.isNotEmpty) {
            currentLocation.value = city;
          } else if (area.isNotEmpty) {
            currentLocation.value = area;
          } else {
            currentLocation.value = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
          }
          if (city.isNotEmpty) userCity = city;
        } else {
          currentLocation.value = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
        }
      } catch (fallbackErr) {
        currentLocation.value = "Lat: ${position.latitude.toStringAsFixed(2)}, Lng: ${position.longitude.toStringAsFixed(2)}";
      }
    } catch (e) {
      log("Error fetching location: $e");
      if (currentLocation.value.isEmpty || currentLocation.value.contains("Detecting")) {
        currentLocation.value = "Tap to refresh location";
      }
    } finally {
      isFetchingLocation = false;
      update();
    }
  }

  /// Show popup dialog when device location service is OFF
  void showLocationOffDialog() {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Icon(Icons.location_off_rounded, color: Colors.red.shade600, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                "Choose Your Current Location",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Your mobile GPS / Location is turned OFF. Please enable location so BamBam Cabs can find your current pickup location.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsValue.appColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Get.back();
                    await Geolocator.openLocationSettings();
                  },
                  icon: const Icon(Icons.location_on_rounded, size: 20),
                  label: const Text(
                    "Turn On Location",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Get.back();
                    await checkAndFetchCurrentLocation(forcePrompt: true);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    "Retry",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Show popup dialog when location permission is needed
  void showLocationPermissionDialog({bool isPermanentlyDenied = false}) {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: Icon(Icons.my_location_rounded, color: Colors.orange.shade700, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                "Location Permission Needed",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "BamBam Cabs needs location access to detect your pickup location and show available cabs near you.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsValue.appColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Get.back();
                    if (isPermanentlyDenied) {
                      await Geolocator.openAppSettings();
                    } else {
                      await Geolocator.requestPermission();
                      await checkAndFetchCurrentLocation(forcePrompt: true);
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    isPermanentlyDenied ? "Open Settings" : "Grant Permission",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Get.back();
                    await checkAndFetchCurrentLocation(forcePrompt: true);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    "Retry",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
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
      await checkAndFetchCurrentLocation(showPopupIfDisabled: false);
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

