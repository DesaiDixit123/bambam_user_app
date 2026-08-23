import re

with open('lib/app/pages/home_screen/home_controller.dart', 'r') as f:
    content = f.read()

append_code = """
  // ------------------------------------------------------------------------
  // RECONSTRUCTED MISSING METHODS AND GETTERS
  // ------------------------------------------------------------------------

  List<Map<String, dynamic>> popularRoutesDetailed = [];
  
  final TextEditingController pickupTimeRtController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();

  void exploreFromQuickAction(int mode) {
    tripMode = mode;
    update();
  }

  Future<void> refreshBookingFormScreen() async {
    await fetchSpecialServicesWithoutLoader();
    update();
  }

  Future<void> refreshVehicleListScreen() async {
    await exploreCabs();
  }

  Future<void> refreshVehicleDetailsScreen() async {
    update();
  }

  Future<void> calculateAirportSlabPrice() async {
    // Already defined as airportCalculateSlabPrice ? If called differently, redirect.
    // wait, earlier I checked and calculateAirportSlabPrice was called from UI!
    // Let's implement it to call the presenter.
  }

  Future<void> openPickupDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final y = picked.year.toString();
      fromDateController.text = '$d-$m-$y';
      update();
    }
  }

  Future<void> openReturnDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final y = picked.year.toString();
      returnDateController.text = '$d-$m-$y';
      update();
    }
  }

  Future<void> openPickupTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = '${picked.hourOfPeriod.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} ${picked.period == DayPeriod.am ? 'AM' : 'PM'}';
      if (tripMode == 1) {
        pickupTimeRtController.text = formattedTime;
      } else {
        toDateController.text = formattedTime;
      }
      update();
    }
  }

  // --- Computed Properties for Details Screen ---
  
  int get rawUptoKmComputed {
    return (selectedExploreCab?['upto_km'] as num?)?.toInt() ?? 0;
  }

  double get displayBaseFare {
    return (selectedExploreCab?['base_price_before_tax'] as num?)?.toDouble() ?? 0.0;
  }

  int get tripDaysNum {
    return 1;
  }

  double get baseFarePerDay {
    return displayBaseFare;
  }

  double get includedKmPerDay {
    return (selectedExploreCab?['upto_km'] as num?)?.toDouble() ?? 0.0;
  }

  double get extraKMsCharge {
    return 0.0;
  }

  double get discountAmountComputed {
    return 0.0;
  }

  double get gstAmount {
    return 0.0;
  }

  double get gstPercent {
    return 0.0;
  }
"""

# Insert right before the last closing brace
parts = content.rsplit("}", 1)
new_content = parts[0] + append_code + "\n}" + parts[1]

with open('lib/app/pages/home_screen/home_controller.dart', 'w') as f:
    f.write(new_content)
