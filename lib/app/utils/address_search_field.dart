// PlaceSearchPage.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
class AddressSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<Map<String, dynamic>>? onSelected;
  final String apiKey;
final bool isPickup;
  final String city;
const AddressSearchField({
  super.key,
  required this.controller,
  required this.apiKey,
  required this.isPickup,
  required this.city,
  this.onSelected,
});


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceSearchPage(
              city: city,
isPickup: isPickup,
              apiKey: apiKey),
          ),
        );

        if (result != null) {
          controller.text = result["display_name"];
          onSelected?.call(result);
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: isPickup
                ? "Select pickup location"
                : "Select drop location",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}

class PlaceSearchPage extends StatefulWidget {
  final String apiKey;
final bool isPickup;
  final String city;
  const PlaceSearchPage({super.key,
  required this.isPickup, 
  required this.apiKey,
    required this.city});

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  TextEditingController searchCtrl = TextEditingController();
  Timer? _debounce;
  List<dynamic> suggestions = [];
  bool isLoading = false;

  // -------------------------------------------------------
  // -------------------------------------------------------
  // FETCH AUTOCOMPLETE SUGGESTIONS
  // -------------------------------------------------------
  Future<void> _searchPlaces(String query, String city) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      setState(() => suggestions = []);
      return;
    }

    setState(() => isLoading = true);

    // 1. First search with clean query in India
    final uri = Uri.https(
      "maps.googleapis.com",
      "/maps/api/place/autocomplete/json",
      {
        "input": cleanQuery,
        "key": widget.apiKey,
        "components": "country:in",
      },
    );

    print("🔍 Autocomplete request: $uri");

    try {
      final resp = await http.get(uri);
      print("📥 Autocomplete response: ${resp.body}");

      final json = jsonDecode(resp.body);
      if (json["status"] == "OK" && json["predictions"] != null && (json["predictions"] as List).isNotEmpty) {
        final predicted = json["predictions"] as List;
        setState(() => suggestions = predicted);
      } else {
        print("⚠️ Google Places Status: ${json['status']}");
        // 2. If ZERO_RESULTS or city context needed
        if (city.trim().isNotEmpty && !cleanQuery.toLowerCase().contains(city.trim().toLowerCase())) {
          final retryUri = Uri.https(
            "maps.googleapis.com",
            "/maps/api/place/autocomplete/json",
            {
              "input": "$cleanQuery, ${city.trim()}",
              "key": widget.apiKey,
              "components": "country:in",
            },
          );
          final retryResp = await http.get(retryUri);
          final retryJson = jsonDecode(retryResp.body);
          if (retryJson["status"] == "OK" && retryJson["predictions"] != null && (retryJson["predictions"] as List).isNotEmpty) {
            setState(() => suggestions = retryJson["predictions"] as List);
          } else {
            await _fetchMmiFallback(cleanQuery, city);
          }
        } else {
          await _fetchMmiFallback(cleanQuery, city);
        }
      }
    } catch (e) {
      print("❌ Autocomplete error: $e");
      await _fetchMmiFallback(cleanQuery, city);
    }

    setState(() => isLoading = false);
  }

  Future<void> _fetchMmiFallback(String query, String city) async {
    try {
      final searchQuery = city.trim().isNotEmpty ? "$query, ${city.trim()}" : query;
      final mmiUri = Uri.parse("https://apis.bambamcabs.com/admin/mmi/search?query=${Uri.encodeComponent(searchQuery)}");
      print("🔍 MMI Fallback request: $mmiUri");
      final resp = await http.get(mmiUri);
      final json = jsonDecode(resp.body);
      if (json["suggestedLocations"] != null) {
        final mmiList = (json["suggestedLocations"] as List).map((loc) {
          final name = loc["placeName"] != null && loc["placeName"].toString().isNotEmpty 
              ? "${loc["placeName"]}, ${loc["placeAddress"]}" 
              : "${loc["placeAddress"]}";
          return {
            "description": name,
            "place_id": loc["eLoc"] ?? "",
            "lat": loc["latitude"],
            "lon": loc["longitude"],
            "is_mmi": true,
          };
        }).toList();
        setState(() => suggestions = mmiList);
      }
    } catch (err) {
      print("❌ MMI Fallback error: $err");
    }
  }

  // -------------------------------------------------------
  // FETCH PLACE DETAILS
  // -------------------------------------------------------
  Future<void> _selectPlace(dynamic item) async {
    if (item is Map && item["is_mmi"] == true) {
      Navigator.pop(context, {
        "display_name": item["description"],
        "lat": item["lat"],
        "lon": item["lon"],
        "raw": item,
      });
      return;
    }

    final placeId = item is Map ? item["place_id"] : item.toString();
    final uri = Uri.https(
      "maps.googleapis.com",
      "/maps/api/place/details/json",
      {
        "place_id": placeId,
        "key": widget.apiKey,
      },
    );

    print("📌 Details request: $uri");

    try {
      final resp = await http.get(uri);
      print("📌 Details response: ${resp.body}");

      final json = jsonDecode(resp.body);

      if (json["status"] == "OK") {
        final r = json["result"];

        Navigator.pop(context, {
          "display_name": r["formatted_address"],
          "lat": r["geometry"]["location"]["lat"],
          "lon": r["geometry"]["location"]["lng"],
          "raw": r,
        });
      } else {
        Navigator.pop(context, {
          "display_name": item is Map ? item["description"] : item.toString(),
          "lat": 0.0,
          "lon": 0.0,
        });
      }
    } catch (e) {
      print("❌ Place Details Error: $e");
      Navigator.pop(context, {
        "display_name": item is Map ? item["description"] : item.toString(),
        "lat": 0.0,
        "lon": 0.0,
      });
    }
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
    appBar: AppBar(
      backgroundColor: isDark ? Colors.black : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      title: Text("Search Places"),
      elevation: 1,
    ),
    body: Column(
      children: [
        // SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Material(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              controller: searchCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: widget.isPickup
                    ? "Search pickup location"
                    : "Search drop location",
                hintStyle:
                    TextStyle(color: isDark ? Colors.grey : Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                suffixIcon: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      )
                    : Icon(Icons.search, color: isDark ? Colors.white : Colors.grey),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 350),
                  () => _searchPlaces(value,widget.city),
                );
              },
            ),
          ),
        ),

        // RESULTS LIST
        Expanded(
          child: suggestions.isEmpty
              ? Center(
                  child: Text(
                    "Start typing to search places...",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                  itemBuilder: (_, i) {
                    final item = suggestions[i];
                    return ListTile(
                      tileColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      title: Text(
                        item["description"],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      onTap: () => _selectPlace(item),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

}

class GooglePlacesHelper {
  static Future<Iterable<String>> searchAddress(String query, String apiKey) async {
    if (query.isEmpty) return const Iterable<String>.empty();
    try {
      final uri = Uri.https(
        "maps.googleapis.com",
        "/maps/api/place/autocomplete/json",
        {
          "input": query,
          "key": apiKey,
          "components": "country:in",
        },
      );
      final resp = await http.get(uri);
      final json = jsonDecode(resp.body);
      if (json["status"] == "OK") {
        final predicted = json["predictions"] as List;
        return predicted.map((e) => e["description"].toString());
      }
    } catch (e) {
      print("Google Places error: $e");
    }
    return const Iterable<String>.empty();
  }
}
