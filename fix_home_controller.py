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
    // Refresh logic
    update();
  }

  Future<void> refreshVehicleListScreen() async {
    await exploreCabs();
  }

  Future<void> refreshVehicleDetailsScreen() async {
    update();
  }

  Future<void> calculateAirportSlabPrice() async {
    // Logic for airport slab price
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
    // Placeholder logic
    return 0;
  }

  double get displayBaseFare {
    return 0.0;
  }

  int get tripDaysNum {
    return 1;
  }

  double get baseFarePerDay {
    return 0.0;
  }

  double get includedKmPerDay {
    return 0.0;
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
}
"""

content = content.replace("}\n", append_code)

with open('lib/app/pages/home_screen/home_controller.dart', 'w') as f:
    f.write(content)
