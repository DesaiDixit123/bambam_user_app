with open('lib/app/pages/home_screen/home_controller.dart', 'r') as f:
    content = f.read()

new_explore_cabs = """
  Future<void> exploreCabs() async {
    final rawFrom = formController.text.trim();
    final pickupDateRaw = fromDateController.text.trim();
    
    // Clean pincodes (6 digit numbers)
    String cleanCity(String val) => val.replaceAll(RegExp(r'\\b\\d{6}\\b'), '').replaceAll(RegExp(r'\\s+'), ' ').replaceAll(' ,', ',').trim();
    final from = cleanCity(rawFrom);

    if (tripMode == 0) {
      final to = cleanCity(toController.text.trim());
      if (from.isNotEmpty && to.isNotEmpty && from.toLowerCase() == to.toLowerCase()) {
        Utility.showMessage("From and To cannot be the same", MessageType.error, null, "OK");
        return;
      }
    } else if (tripMode == 1) {
      for (var c in toControllers) {
        final to = cleanCity(c.text.trim());
        if (to.isNotEmpty && from.toLowerCase() == to.toLowerCase()) {
          Utility.showMessage("From and To cannot be the same", MessageType.error, null, "OK");
          return;
        }
      }
    }

    // Validate depending on tripMode
    if (tripMode == 0) {
      final to = cleanCity(toController.text.trim());
      if (from.isEmpty || to.isEmpty || pickupDateRaw.isEmpty) {
        Utility.showMessage("Please fill From/To/Pickup date", MessageType.error, null, "OK");
        return;
      }
      if (toDateController.text.trim().isEmpty) {
        Utility.showMessage("Please fill Pickup date/time", MessageType.error, null, "OK");
        return;
      }
    } else if (tripMode == 1) {
      final toList = toControllers.map((c) => cleanCity(c.text.trim())).where((s) => s.isNotEmpty).toList();
      if (from.isEmpty || toList.isEmpty || pickupDateRaw.isEmpty || returnDateController.text.trim().isEmpty) {
        Utility.showMessage("Please fill From/To/Pickup/Return date", MessageType.error, null, "OK");
        return;
      }
    } else if (tripMode == 2) {
      final city = cleanCity(localCityController.text.trim());
      if (city.isEmpty || pickupDateRaw.isEmpty) {
        Utility.showMessage("Please select City and Pickup date", MessageType.error, null, "OK");
        return;
      }
    } else if (tripMode == 3) {
      final validationTo = cleanCity(toController.text.trim());
      if (from.isEmpty || validationTo.isEmpty || pickupDateRaw.isEmpty) {
        Utility.showMessage("Please fill all details", MessageType.error, null, "OK");
        return;
      }
    }

    Map<String, dynamic> body = {};
    if (tripMode == 0) {
      body = {
        "trip_type": "Oneway",
        "from": from,
        "to": cleanCity(toController.text.trim()),
        "pickup_date": _formatToApiDate(pickupDateRaw),
        "pickup_time": toDateController.text.trim().isNotEmpty ? toDateController.text.trim() : "09:00 AM",
      };
    } else if (tripMode == 1) {
      final toList = toControllers.map((c) => cleanCity(c.text.trim())).where((s) => s.isNotEmpty).toList();
      final returnDateRaw = returnDateController.text.trim();
      final pTime = pickupTimeRtController.text.trim();
      body = {
        "trip_type": "Round Trip",
        "from": from,
        "to": toList,
        "pickup_date": _formatToApiDate(pickupDateRaw),
        "return_date": _formatToApiDate(returnDateRaw),
        "pickup_time": pTime.isNotEmpty ? pTime : "09:00 AM",
      };
    } else if (tripMode == 2) {
      final city = cleanCity(localCityController.text.trim());
      final selectedBlock = rentalBlocks.isNotEmpty ? rentalBlocks[selectedRentalIndex] : null;
      final pTime = toDateController.text.trim();
      body = {
        "trip_type": "Local Rental Trip",
        "city": city,
        "pickup_date": _formatToApiDate(pickupDateRaw),
        "pickup_time": pTime.isNotEmpty ? pTime : "09:00 AM",
        "selected_hours": selectedBlock?['hours'].toString(),
        "selected_km": selectedBlock?['km'].toString(),
      };
    } else if (tripMode == 3) {
      final pTime = toDateController.text.trim();
      body = {
        "trip_type": "Airport",
        "pickup_type": pickupType,
        "from": from,
        "to": cleanCity(toController.text.trim()),
        "pickup_date": _formatToApiDate(pickupDateRaw),
        "pickup_time": pTime.isNotEmpty ? pTime : "09:00 AM",
      };
    }

    final res = await homePresenter.exploreCabs(body, showLoader: true);
    if (res.hasError) {
      try {
        final bodyRes = jsonDecode(res.data);
        Utility.showMessage((bodyRes['Message'] ?? bodyRes['message'] ?? res.data).toString(), MessageType.error, null, 'OK');
      } catch (_) {
        Utility.showMessage(res.data ?? 'Failed to search', MessageType.error, null, 'OK');
      }
      return;
    }

    try {
      final json = jsonDecode(res.data) as Map<String, dynamic>;
      datta = json['Data'] as Map<String, dynamic>?;
      exploreTrips = datta?['trips'] as List<dynamic>? ?? [];

      if (tripMode == 2) {
        rentalBlocks = [];
        if (exploreTrips.isNotEmpty) {
          final trip = exploreTrips[0];
          final vehiclePricing = trip['vehicle_pricing'] as List? ?? [];
          final Set<String> seen = {};
          for (var vp in vehiclePricing) {
            final blocks = vp['pricing_blocks'] as List? ?? [];
            for (var block in blocks) {
              final b = Map<String, dynamic>.from(block);
              final key = "${b['hours']}_${b['km']}";
              if (seen.add(key)) {
                rentalBlocks.add(b);
              }
            }
          }
          rentalBlocks.sort((a, b) => (a['hours'] as int).compareTo(b['hours'] as int));
        }

        if (rentalBlocks.isNotEmpty && selectedRentalIndex >= rentalBlocks.length) {
          selectedRentalIndex = 0;
        }

        if (rentalBlocks.isNotEmpty) {
          final first = rentalBlocks[0];
          final body2 = {
            "trip_type": "Local Rental Trip",
            "city": city,
            "pickup_date": _formatToApiDate(fromDateController.text),
            "pickup_time": toDateController.text,
            "selected_hours": first['hours'].toString(),
            "selected_km": first['km'].toString(),
          };
          final res2 = await homePresenter.exploreCabs(body2, showLoader: false);
          final json2 = jsonDecode(res2.data) as Map<String, dynamic>;
          datta = json2['Data'];
          update();
        }
      }

      exploreVehicles = datta?['vehicles'] as List<dynamic>? ?? [];
      exploreId = datta?['exploreId']?.toString() ?? '';
      totalKm = (datta?['total_km'] is num) ? (datta?['total_km'] as num).toDouble() : 0;
      finalPrice = (datta?['final_price'] is num) ? (datta?['final_price'] as num).toDouble() : 0;
      vehicleExpanded = List<bool>.filled(exploreVehicles.length, false);
      update();

      RouteManagement.gotoSelectVehicalScreen();
    } catch (e) {
      Utility.showMessage('Failed to parse results', MessageType.error, null, 'OK');
    }
  }
"""

start_str = "  Future<void> exploreCabs() async {"
end_str = "  // ---------- processBooking"

start_idx = content.find(start_str)
end_idx = content.find(end_str, start_idx)

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + new_explore_cabs.strip() + '\n\n' + content[end_idx:]
    with open('lib/app/pages/home_screen/home_controller.dart', 'w') as f:
        f.write(content)
else:
    print("Could not find boundaries")
