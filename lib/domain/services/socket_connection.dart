// import 'package:get/get.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:bam_bam_user/data/data.dart';
// import 'package:bam_bam_user/domain/domain.dart';

// abstract class SocketConnection {
//   static IO.Socket? socket;

//   // static socketDisconnect() {
//   //   socket?.disconnect();
//   // }

//   static initSocket() {
//     socket = IO.io(ApiWrapper.baseUrl, <String, dynamic>{
//       'autoConnect': false,
//       'transports': ['websocket'],
//     });
//     socket!.connect();
//     socket!.onConnect((_) {
//       print("Conttecty SuseesFully...");
//       print(Get.find<Repository>().getStringValue(LocalKeys.chanelId));
//       // socket!.emit('init', {
//       //   'channelID': Get.find<Repository>().getStringValue(LocalKeys.chanelId),
//       // });
//     });

//     socket!.on(Get.find<Repository>().getStringValue(LocalKeys.chanelId),
//         (data) async {
//       print(data);
//       if (data['event'] == 'onthemesave') {
//         Get.forceAppUpdate();
//       }
//     });
//     socket!.onDisconnect((_) => print('Connection Disconnection'));
//     socket!.onConnectError((err) => print(err));
//     socket!.onError((err) => print(err));
//   }
// }
