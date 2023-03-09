import 'dart:async';

import 'package:flutter/material.dart';
import '../../../controllers/authController/auth_controller.dart';
import 'package:get/get.dart';

import '../../values/my_colors.dart';
import '../../values/my_imgs.dart';
import '../../values/ui_size_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthController authController = Get.put(AuthController());
  @override
  void initState() {
    // Get.log("${GetStorage().read("accessToken")}");
    // authController.checkConnectionSplash();
    // TODO: implement initState
    super.initState();
    Timer(const Duration(seconds: 3), () {
      authController.checkConnectionSplash();
      // Get.to(onBoardingScreen());
    });
  }
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        backgroundColor: MyColors.primaryColor,
        body: Center(child: Image.asset(MyImgs.chat,height: getHeight(34),))

    );
  }
}