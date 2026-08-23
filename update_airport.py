import re

with open('lib/app/pages/home_screen/home_controller.dart', 'r') as f:
    content = f.read()

# Replace the empty calculateAirportSlabPrice with the correct one
new_method = """
  Future<void> calculateAirportSlabPrice() async {
    if (selectedVehicle == null || selectedExploreCab == null) return;
    
    final payload = {
      "vehicle_type_id": selectedVehicle!['_id'],
      "from": selectedExploreCab!['from'] ?? "",
      "to": (selectedExploreCab!['to'] is List) ? (selectedExploreCab!['to'][0] ?? "") : (selectedExploreCab!['to'] ?? ""),
    };
    
    final res = await homePresenter.airportCalculateSlabPrice(payload, showLoader: false);
    if (!res.hasError) {
      try {
        final json = jsonDecode(res.data);
        if (json['IsSuccess'] == true) {
          final slabData = json['Data'];
          // Merge slab data into selectedExploreCab so getters can use it
          if (slabData != null) {
            selectedExploreCab!['base_price_before_tax'] = slabData['base_price_before_tax'];
            selectedExploreCab!['upto_km'] = slabData['upto_km'];
            update();
          }
        }
      } catch (_) {}
    }
  }
"""

content = re.sub(r'  Future<void> calculateAirportSlabPrice\(\) async \{\s*\}', new_method.strip(), content)

with open('lib/app/pages/home_screen/home_controller.dart', 'w') as f:
    f.write(content)
