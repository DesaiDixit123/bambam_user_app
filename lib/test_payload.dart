import 'dart:convert';
void main() {
  final body = {
    "trip_type": "Airport",
    "pickup_type": "pickup",
    "from": "Sardar Vallabhbhai Patel International Airport, Ahmedabad, Gujarat, India",
    "to": "Bopal, Ahmedabad, Gujarat, India",
    "pickup_date": "2026-07-10",
    "pickup_time": "10:30 AM",
  };
  print(jsonEncode(body));
}
