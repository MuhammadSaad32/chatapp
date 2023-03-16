import 'package:chat_app/controllers/authController/auth_controller.dart';
import 'package:chat_app/ui/screens/allusers/paginated_data_screen.dart';
import 'package:chat_app/ui/screens/auth/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';

import 'data/bindings/bindings.dart';
Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp().then((value) {
    Get.put(AuthController());
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
       // primarySwatch:Colors
      ),
      debugShowCheckedModeBanner: false,
      getPages: [
        GetPage<void>(
            name: '/', page: () => PaginatedDataScreen(), bindings: [DataBinding()]),
      ],
    );
  }
}

