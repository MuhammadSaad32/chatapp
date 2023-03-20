import 'package:chat_app/controllers/audioController/audio_controller.dart';
import 'package:chat_app/controllers/chatController/chat_controller.dart';
import 'package:chat_app/controllers/homeController/home_controller.dart';
import 'package:get/get.dart';
import '../../controllers/authController/auth_controller.dart';
class DataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => AudioController(), fenix: true);
  }
}