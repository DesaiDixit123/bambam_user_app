import 'dart:async';
import 'dart:convert';
import 'package:bam_bam_user/app/utils/asset_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
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
    final cleanCity = city.split(',').first.trim();
    final hint = cleanCity.isNotEmpty
        ? "Search address in $cleanCity"
        : (isPickup ? "Select pickup location" : "Select drop location");

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceSearchPage(
              city: city,
              isPickup: isPickup,
              apiKey: apiKey,
            ),
          ),
        );

        if (result != null) {
          controller.text = result["display_name"] ?? '';
          onSelected?.call(result);
        }
      },
      child: AbsorbPointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    isPickup ? Icons.my_location : Icons.location_on,
                    size: 16,
                    color: isPickup ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPickup ? "Pickup Location (From)" : "Drop Location (To)",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B1727),
                    ),
                  ),
                  const Text(
                    " *",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0B1727),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFF96602), width: 1.5),
                ),
                suffixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFF96602),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceSearchPage extends StatefulWidget {
  final String apiKey;
  final bool isPickup;
  final String city;

  const PlaceSearchPage({
    super.key,
    required this.isPickup,
    required this.apiKey,
    required this.city,
  });

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  TextEditingController searchCtrl = TextEditingController();
  Timer? _debounce;
  List<dynamic> suggestions = [];
  bool isLoading = false;

  // -------------------------------------------------------
  // FETCH AUTOCOMPLETE SUGGESTIONS
  // -------------------------------------------------------
  // -------------------------------------------------------
  // FETCH AUTOCOMPLETE SUGGESTIONS (Pure Google Places API)
  // -------------------------------------------------------
  Future<void> _searchPlaces(String query, String city) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      setState(() => suggestions = []);
      return;
    }

    setState(() => isLoading = true);

    final cleanCity = city.split(',').first.trim();
    // 1. Like website: append city name if not already included in query
    final inputWithCity = (cleanCity.isNotEmpty &&
            !cleanQuery.toLowerCase().contains(cleanCity.toLowerCase()))
        ? "$cleanQuery, $cleanCity"
        : cleanQuery;

    try {
      var preds = await _fetchGooglePredictions(inputWithCity);

      // If zero results and input had city appended, retry with pure cleanQuery
      if (preds.isEmpty && inputWithCity != cleanQuery) {
        preds = await _fetchGooglePredictions(cleanQuery);
      }

      // Sort / prioritize results matching the city
      if (cleanCity.isNotEmpty && preds.isNotEmpty) {
        final lowerCity = cleanCity.toLowerCase();
        preds.sort((a, b) {
          final aDesc = a["description"].toString().toLowerCase();
          final bDesc = b["description"].toString().toLowerCase();
          final aHas = aDesc.contains(lowerCity);
          final bHas = bDesc.contains(lowerCity);
          if (aHas && !bHas) return -1;
          if (!aHas && bHas) return 1;
          return 0;
        });
      }

      setState(() => suggestions = preds);
    } catch (e) {
      debugPrint("❌ Autocomplete error: $e");
      setState(() => suggestions = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGooglePredictions(String input) async {
    final uri = Uri.https(
      "maps.googleapis.com",
      "/maps/api/place/autocomplete/json",
      {
        "input": input,
        "key": widget.apiKey,
        "components": "country:in",
      },
    );

    debugPrint("🔍 Google Autocomplete request: $uri");
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      final json = jsonDecode(resp.body);

      if (json["status"] == "OK" && json["predictions"] != null) {
        return (json["predictions"] as List).map<Map<String, dynamic>>((p) {
          return {
            "description": p["description"] ?? "",
            "place_id": p["place_id"] ?? "",
            "main_text": p["structured_formatting"]?["main_text"] ??
                p["description"] ??
                "",
            "secondary_text":
                p["structured_formatting"]?["secondary_text"] ?? "",
            "is_google": true,
          };
        }).toList();
      } else {
        if (json["status"] == "REQUEST_DENIED") {
          debugPrint("❌ Google Places REQUEST_DENIED: ${json["error_message"]}");
        }
        return [];
      }
    } catch (e) {
      debugPrint("❌ Google Autocomplete exception: $e");
      return [];
    }
  }

  // -------------------------------------------------------
  // FETCH PLACE DETAILS (Google Places Details API)
  // -------------------------------------------------------
  Future<void> _selectPlace(dynamic item) async {
    final String address = item is Map
        ? (item["description"] ?? item["placeAddress"] ?? item.toString())
        : item.toString();

    double? lat = (item is Map && item["lat"] != null && item["lat"] != 0.0)
        ? double.tryParse(item["lat"].toString())
        : null;
    double? lon = (item is Map && item["lon"] != null && item["lon"] != 0.0)
        ? double.tryParse(item["lon"].toString())
        : null;

    final placeId = item is Map ? item["place_id"] : null;
    if (placeId != null && placeId.toString().isNotEmpty) {
      try {
        final uri = Uri.https(
          "maps.googleapis.com",
          "/maps/api/place/details/json",
          {
            "place_id": placeId.toString(),
            "key": widget.apiKey,
            "fields": "geometry",
          },
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 4));
        final json = jsonDecode(resp.body);
        if (json["status"] == "OK") {
          final r = json["result"];
          lat = (r["geometry"]?["location"]?["lat"] as num?)?.toDouble();
          lon = (r["geometry"]?["location"]?["lng"] as num?)?.toDouble();
        }
      } catch (e) {
        debugPrint("❌ Google Place Details exception: $e");
      }
    }

    if (lat == null || lon == null || lat == 0.0 || lon == 0.0) {
      final coords =
          await GooglePlacesHelper.getCoordinates(address, widget.apiKey);
      if (coords != null) {
        lat = coords["lat"];
        lon = coords["lng"];
      }
    }

    if (!mounted) return;
    Navigator.pop(context, {
      "display_name": address,
      "lat": lat,
      "lon": lon,
      "place_id": placeId,
      "raw": item,
    });
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanCity = widget.city.split(',').first.trim();
    final hint = cleanCity.isNotEmpty
        ? "Search address in $cleanCity"
        : (widget.isPickup ? "Search pickup location" : "Search drop location");

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: Text(
          widget.isPickup ? "Select Pickup Location" : "Select Drop Location",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
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
                  prefixIcon: Icon(
                    widget.isPickup ? Icons.my_location : Icons.location_on,
                    size: 20,
                    color: widget.isPickup ? Colors.green : Colors.red,
                  ),
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey : const Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                  suffixIcon: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFFF96602),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: isDark ? Colors.white : const Color(0xFFF96602),
                        ),
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 350),
                    () => _searchPlaces(value, widget.city),
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
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                    itemBuilder: (_, i) {
                      final item = suggestions[i];
                      final mainText = item["main_text"]?.toString() ??
                          item["description"]?.toString() ??
                          "";
                      final secondaryText =
                          item["secondary_text"]?.toString() ?? "";

                      return ListTile(
                        tileColor: isDark
                            ? Colors.grey.shade800
                            : Colors.transparent,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (widget.isPickup
                                    ? Colors.green
                                    : Colors.red)
                                .withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isPickup
                                ? Icons.my_location
                                : Icons.location_on_outlined,
                            size: 18,
                            color: widget.isPickup ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          mainText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        subtitle: secondaryText.isNotEmpty
                            ? Text(
                                secondaryText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : const Color(0xFF6B7280),
                                ),
                              )
                            : null,
                        onTap: () => _selectPlace(item),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 6
              : 10,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : const Color(0xFFF9FAFB),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "powered by ",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              AssetConstants.ic_google,
              height: 14,
            ),
            const SizedBox(width: 4),
            Text(
              "Google",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GooglePlacesHelper {
  static final Map<String, List<String>> _cache = {};

  static Future<Iterable<String>> searchAddress(String query, String apiKey) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return const Iterable<String>.empty();

    if (_cache.containsKey(cleanQuery)) {
      return _cache[cleanQuery]!;
    }

    try {
      final uri = Uri.https(
        "maps.googleapis.com",
        "/maps/api/place/autocomplete/json",
        {
          "input": cleanQuery,
          "key": apiKey,
          "components": "country:in",
        },
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      final json = jsonDecode(resp.body);
      if (json["status"] == "OK" && json["predictions"] != null && (json["predictions"] as List).isNotEmpty) {
        final predicted = json["predictions"] as List;
        final list = predicted.map((e) => e["description"].toString()).toList();
        _cache[cleanQuery] = list;
        return list;
      }
    } catch (e) {
      debugPrint("❌ Google Places searchAddress error: $e");
    }
    return const Iterable<String>.empty();
  }


  static Future<List<String>> searchCities(String query, String apiKey, {String? stateName}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];
    try {
      final input = (stateName != null && stateName.trim().isNotEmpty)
          ? "$cleanQuery, ${stateName.trim()}"
          : cleanQuery;
      final uri = Uri.https(
        "maps.googleapis.com",
        "/maps/api/place/autocomplete/json",
        {
          "input": input,
          "key": apiKey,
          "types": "(cities)",
          "components": "country:in",
        },
      );
      final resp = await http.get(uri);
      final json = jsonDecode(resp.body);
      if (json["status"] == "OK" && json["predictions"] != null) {
        final predicted = json["predictions"] as List;
        return predicted.map((e) {
          final mainText = e["structured_formatting"]?["main_text"];
          if (mainText != null && mainText.toString().trim().isNotEmpty) {
            return mainText.toString().trim();
          }
          final desc = e["description"].toString();
          return desc.split(',').first.trim();
        }).where((name) => name.isNotEmpty).toSet().toList();
      }
    } catch (e) {
      print("Google Places searchCities error: $e");
    }
    return [];
  }

  static Future<Map<String, double>?> getCoordinates(String address, String apiKey) async {
    final clean = address.trim();
    if (clean.isEmpty) return null;

    // Helper to query Nominatim
    Future<Map<String, double>?> queryNominatim(String q) async {
      try {
        final nomUri = Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&countrycodes=in&limit=5",
        );
        final resp = await http.get(nomUri, headers: {'User-Agent': 'BambamCabs/1.0'}).timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final list = jsonDecode(resp.body);
          if (list is List && list.isNotEmpty) {
            // Filter out rural Taluka/Tehsil boundary results if not explicitly requested
            final bool queryWantsTaluka = q.toLowerCase().contains('taluka') || q.toLowerCase().contains('tehsil');
            final valid = list.where((item) {
              if (item is! Map) return false;
              final name = (item["name"] ?? "").toString().toLowerCase();
              final display = (item["display_name"] ?? "").toString().toLowerCase();
              final cls = (item["class"] ?? "").toString().toLowerCase();
              final type = (item["type"] ?? "").toString().toLowerCase();
              if (!queryWantsTaluka && (name.contains("taluka") || name.contains("tehsil") || (cls == "boundary" && type == "administrative" && display.contains("taluka")))) {
                return false;
              }
              return true;
            }).toList();

            if (valid.isNotEmpty) {
              final target = valid.first;
              final lat = double.tryParse(target["lat"].toString());
              final lon = double.tryParse(target["lon"].toString());
              if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
                return {"lat": lat, "lng": lon};
              }
            }
          }
        }
      } catch (_) {}
      return null;
    }

    // 0. Check 6-digit Indian PIN code if present in address (e.g. 395009, 380058)
    final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(clean);
    if (pinMatch != null) {
      final pincode = pinMatch.group(0)!;
      final area = clean.split(',').first.trim();
      final resPin = await queryNominatim("$area, $pincode, India");
      if (resPin != null) return resPin;
      final resDirectPin = await queryNominatim("$pincode, India");
      if (resDirectPin != null) return resDirectPin;
    }

    // 1. Try native geocoder (Google Play Services / iOS CoreLocation)
    try {
      final locations = await locationFromAddress(clean).timeout(const Duration(seconds: 4));
      if (locations.isNotEmpty && locations.first.latitude != 0.0) {
        return {
          "lat": locations.first.latitude,
          "lng": locations.first.longitude,
        };
      }
    } catch (_) {}

    // 2. Try Nominatim with exact clean address
    final res1 = await queryNominatim(clean);
    if (res1 != null) return res1;

    // 3. Fallback: Try area + city, area Gam, area Road if exact query only matched Taluka
    final parts = clean.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final area = parts[0];
      final city = parts[1];
      final resGam = await queryNominatim("$area Gam, $city");
      if (resGam != null) return resGam;
      final resRoad = await queryNominatim("$area Road, $city");
      if (resRoad != null) return resRoad;
      final resSimple = await queryNominatim("$area, $city");
      if (resSimple != null) return resSimple;
    }

    // 4. Fallback: Try with simplified query variations (e.g. "Kite Museum, Sanskar Kendra, Paldi, Ahmedabad")
    if (parts.length > 2) {
      // Variation A: remove "Opposite...", "Near...", "Behind..." modifiers
      final cleanedParts = parts.where((p) {
        final lower = p.toLowerCase();
        return !lower.startsWith('opposite') &&
               !lower.startsWith('near') &&
               !lower.startsWith('behind') &&
               !lower.startsWith('opp') &&
               !lower.startsWith('nr');
      }).toList();
      if (cleanedParts.length != parts.length && cleanedParts.isNotEmpty) {
        final resA = await queryNominatim(cleanedParts.join(', '));
        if (resA != null) return resA;
      }

      // Variation B: First landmark + City/State (e.g. "Sanskar Kendra, Ahmedabad")
      final cityPart = parts.length > 2 ? parts[parts.length - 2] : parts.last;
      for (int i = 0; i < parts.length && i < 3; i++) {
        final p = parts[i];
        if (p.toLowerCase().startsWith('opposite') || p.toLowerCase().startsWith('near')) continue;
        final resB = await queryNominatim("$p, $cityPart");
        if (resB != null) return resB;
        final resBRoad = await queryNominatim("$p Road, $cityPart");
        if (resBRoad != null) return resBRoad;
      }

      // Variation C: Last 3 components (e.g. "Paldi, Ahmedabad, 380007")
      if (parts.length >= 3) {
        final last3 = parts.sublist(parts.length - 3).join(', ');
        final resC = await queryNominatim(last3);
        if (resC != null) return resC;
      }
    }


    // 5. Fallback: Google Geocode
    try {
      final uri = Uri.https(
        "maps.googleapis.com",
        "/maps/api/geocode/json",
        {
          "address": clean,
          "key": apiKey,
          "components": "country:in",
        },
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json["status"] == "OK" && (json["results"] as List).isNotEmpty) {
          final loc = json["results"][0]["geometry"]["location"];
          return {
            "lat": (loc["lat"] as num).toDouble(),
            "lng": (loc["lng"] as num).toDouble(),
          };
        }
      }
    } catch (_) {}

    return null;
  }

  /// Calculate driving distance between pickup and drop using OSRM / Google Maps / Backend
  static Future<double?> calculateDrivingDistance({
    required String origin,
    required String destination,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    String? apiKey,
  }) async {
    // 1. Resolve coordinates if missing
    double? oLat = (originLat != null && originLat != 0.0) ? originLat : null;
    double? oLng = (originLng != null && originLng != 0.0) ? originLng : null;
    double? dLat = (destLat != null && destLat != 0.0) ? destLat : null;
    double? dLng = (destLng != null && destLng != 0.0) ? destLng : null;

    if (oLat == null || oLng == null) {
      final c = await getCoordinates(origin, apiKey ?? '');
      if (c != null) {
        oLat = c["lat"];
        oLng = c["lng"];
      }
    }

    if (dLat == null || dLng == null) {
      final c = await getCoordinates(destination, apiKey ?? '');
      if (c != null) {
        dLat = c["lat"];
        dLng = c["lng"];
      }
    }

    final origStr = (oLat != null && oLng != null) ? "$oLat,$oLng" : origin.trim();
    final destStr = (dLat != null && dLng != null) ? "$dLat,$dLng" : destination.trim();

    // 1. PRIMARY: Google Distance Matrix API (Matching Website exactly)
    if (origStr.isNotEmpty && destStr.isNotEmpty && apiKey != null && apiKey.isNotEmpty) {
      try {
        final uri = Uri.https(
          "maps.googleapis.com",
          "/maps/api/distancematrix/json",
          {
            "origins": origStr,
            "destinations": destStr,
            "key": apiKey,
            "mode": "driving",
          },
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body);
          final element = json["rows"]?[0]?["elements"]?[0];
          if (element != null && element["status"] == "OK" && element["distance"] != null) {
            final meters = (element["distance"]["value"] as num).toDouble();
            final km = (meters / 1000.0).roundToDouble();
            if (km > 0) {
              debugPrint("[Distance Calc] Google Distance Matrix success: $km KM");
              return km;
            }
          }
        }
      } catch (e) {
        debugPrint("[Distance Calc] Google Distance Matrix error: $e");
      }

      // 2. Fallback: Google Directions API
      try {
        final uri = Uri.https(
          "maps.googleapis.com",
          "/maps/api/directions/json",
          {
            "origin": origStr,
            "destination": destStr,
            "key": apiKey,
            "mode": "driving",
          },
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body);
          if (json["status"] == "OK" && (json["routes"] as List).isNotEmpty) {
            final legs = json["routes"][0]["legs"] as List;
            double totalMeters = 0.0;
            for (final leg in legs) {
              totalMeters += (leg["distance"]?["value"] as num?)?.toDouble() ?? 0.0;
            }
            if (totalMeters > 0) {
              final km = (totalMeters / 1000.0).roundToDouble();
              debugPrint("[Distance Calc] Google Directions success: $km KM");
              return km;
            }
          }
        }
      } catch (e) {
        debugPrint("[Distance Calc] Google Directions error: $e");
      }
    }

    // 3. Fallback: OSRM driving distance (if Google API unavailable)
    if (oLat != null && oLng != null && dLat != null && dLng != null) {
      try {
        final osrmUri = Uri.parse(
          "https://router.project-osrm.org/route/v1/driving/$oLng,$oLat;$dLng,$dLat?overview=false",
        );
        final resp = await http.get(osrmUri).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body);
          if (json["code"] == "Ok" && (json["routes"] as List).isNotEmpty) {
            final meters = (json["routes"][0]["distance"] as num).toDouble();
            final km = (meters / 1000.0).roundToDouble();
            if (km > 0) {
              debugPrint("[Distance Calc] OSRM success: $km KM");
              return km;
            }
          }
        }
      } catch (e) {
        debugPrint("[Distance Calc] OSRM error: $e");
      }
    }

    // 4. Fallback: Backend Google Distance endpoint
    try {
      final backendUri = Uri.parse(
        "https://apis.bambamcabs.com/user/google-distance?origin=${Uri.encodeComponent(origStr)}&destination=${Uri.encodeComponent(destStr)}",
      );
      final resp = await http.get(backendUri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json["Data"] != null && json["Data"]["distanceKm"] != null) {
          return (json["Data"]["distanceKm"] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint("Backend google-distance error: $e");
    }

    return null;
  }
}
