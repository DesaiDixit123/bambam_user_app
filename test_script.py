with open('lib/app/pages/home_screen/home_controller.dart', 'r') as f:
    content = f.read()

# I will add prints to investigate if exploreCabs is failing
content = content.replace("Utility.showMessage(\"From and To cannot be the same\", MessageType.error, null, \"OK\");", "print('DEBUG: From/To same'); Utility.showMessage(\"From and To cannot be the same\", MessageType.error, null, \"OK\");")
content = content.replace("Utility.showMessage(\"Please fill From/To/Pickup date\", MessageType.error, null, \"OK\");", "print('DEBUG: From/To/Date empty'); Utility.showMessage(\"Please fill From/To/Pickup date\", MessageType.error, null, \"OK\");")
content = content.replace("Utility.showMessage(\"Please fill Pickup date/time\", MessageType.error, null, \"OK\");", "print('DEBUG: Time empty'); Utility.showMessage(\"Please fill Pickup date/time\", MessageType.error, null, \"OK\");")
content = content.replace("Utility.showMessage(\"Please fill all details\", MessageType.error, null, \"OK\");", "print('DEBUG: Details empty'); Utility.showMessage(\"Please fill all details\", MessageType.error, null, \"OK\");")

content = content.replace("if (res.hasError) {", "if (res.hasError) { print('DEBUG: API Error. res.data = ${res.data}');")
content = content.replace("} catch (e) {", "} catch (e, st) { print('DEBUG: Exception caught: $e\\n$st');")
content = content.replace("Utility.showMessage('Failed to parse results', MessageType.error, null, 'OK');", "Utility.showMessage('Failed to parse results: $e', MessageType.error, null, 'OK');")

with open('lib/app/pages/home_screen/home_controller.dart', 'w') as f:
    f.write(content)
