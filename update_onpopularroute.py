import re

with open('lib/app/pages/home_screen/home_controller.dart', 'r') as f:
    content = f.read()

new_method = """
  void onPopularRouteSelected(dynamic route) {
    try {
      if (route is String) {
        final parts = route.split("→");
        if (parts.length == 2) {
          final from = parts[0].trim();
          final to = parts[1].trim();
          formController.text = from;
          toController.text = to;
          toControllers = [TextEditingController(text: to)];
          tripMode = 0;
          update();
        }
      } else if (route is Map) {
        formController.text = route["from"]?.toString() ?? "";
        toController.text = route["to"]?.toString() ?? "";
        toControllers = [TextEditingController(text: route["to"]?.toString() ?? "")];
        final type = route["trip_type"]?.toString() ?? "Oneway";
        if (type == "Round Trip") tripMode = 1;
        else if (type == "Local Rental Trip") tripMode = 2;
        else if (type == "Airport") tripMode = 3;
        else tripMode = 0;
        update();
      }
    } catch (e) {
      debugPrint("Error parsing popular route: $e");
    }
  }
"""

content = re.sub(r'  void onPopularRouteSelected\(String route\) \{\n.*?    \}\n  \}', new_method.strip(), content, flags=re.DOTALL)

with open('lib/app/pages/home_screen/home_controller.dart', 'w') as f:
    f.write(content)
