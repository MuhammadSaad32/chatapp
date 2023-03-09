import 'package:chat_app/controllers/homeController/home_controller.dart';
import 'package:chat_app/ui/screens/auth/login/login_screen.dart';
import 'package:chat_app/ui/screens/auth/signup/signup_screen.dart';
import 'package:chat_app/ui/widgets/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/getServices/CheckConnectionService.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/widgets/progress_bar.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  // AuthController authController =Get.put(AuthController());
  bool isLoading = true;
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> signUpFormKey = GlobalKey<FormState>();
  final auth = FirebaseAuth.instance;
  RxBool hidePassword = true.obs;
  RxBool hideConfirmPass = true.obs;
  RxBool hidePassLogin = true.obs;
  final CheckConnectionService connectionService = CheckConnectionService();
  final fireStore = FirebaseFirestore.instance;
  //HomeController homeController = Get.put(HomeController());

  // Sign Up Text Controllers
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  // Login Editing controller

  TextEditingController emailControllerLogin = TextEditingController();
  TextEditingController passwordControllerLogin = TextEditingController();
//showPassword(){
  // showPass.value = !showPass.value;
  // update();
//}
  onLoginButton() async {
    Get.dialog(ProgressBar());
    final isValid = loginFormKey.currentState!.validate();
    if (!isValid) {
      Get.back();
      return;
    } else {
      loginUser(
          mail: emailControllerLogin.text.trim(),
          pass: passwordControllerLogin.text);
    }
  }

  onSignUpButton() async {
    Get.dialog(ProgressBar());
    final isValid = signUpFormKey.currentState!.validate();
    if (!isValid) {
      Get.back();
      return;
    } else {
      print("Else Called");
      print("Value is ${emailController.text}");
      print("Value is ${passwordController.text}");
      print("Value is ${firstNameController.text}");
      print("Value is ${lastNameController.text}");
      await registerUser(
        email: emailController.text.trim(),
        fName: firstNameController.text,
        pas: passwordController.text,
        lName: lastNameController.text,
      );
    }
  }

  registerUser({
    required String email,
    required String pas,
    required String fName,
    required String lName,
  }) async {
    await connectionService.checkConnection().then((internet) async {
      if (!internet) {
        CustomToast.failToast(message: "No Internet Connection");
      }
      else {
        try {
          print("email is $email");
          print("email is $pas");
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email, password: pas);
          await FirebaseFirestore.instance.collection("Users").doc(auth.currentUser!.uid.toString()).set({
            'id': auth.currentUser!.uid.toString(),
            'email': email,
            'password': pas,
            'firstName': fName,
            'lastName': lName,
            'status': "Offline",
          },SetOptions(merge: true)).then((value) async {
            CustomToast.successToast(message: "Account Created Successfully");
            Get.offAll(LoginScreen());
          }).onError((error, stackTrace) {
            Get.back();
            CustomToast.failToast(message: "Unsuccessful Login");
          });
        } catch (e) {
          print("${e}");
          CustomToast.failToast(message: e.toString());
          // Get.showSnackbar(GetSnackBar(
          //   message: e.toString(),
          //   snackStyle: SnackStyle.FLOATING,
          //   backgroundColor: Colors.red,
          //   duration: const Duration(seconds: 3),
          // ));
        }
        //Get.log("Email is $mail");
        // b    Get.log("Password is $pass");
      }
    });
  }

  loginUser({required String mail, required String pass}) async {
    await connectionService.checkConnection().then((internet) async {
      if (!internet) {
        CustomToast.failToast(message: "No Internet Connection");
      } else {
        try {
         Get.log("mail sent to controller is $mail");
         Get.log("mail sent to controller is $pass");
          await auth.signInWithEmailAndPassword(email: mail, password: pass)
              .then((value) async {
            await Get.find<HomeController>().getCurrentUserID();
            await Get.find<HomeController>().getDataCurrentUser();
            await Get.find<HomeController>().setStatus('Online');
            GetStorage().write(auth.currentUser!.uid.toString(), Get.find<HomeController>().currentUserID);
            GetStorage().write('FirstName${auth.currentUser!.uid.toString()}', Get.find<HomeController>().loggedInUserFirstName);
            GetStorage().write('LastName${auth.currentUser!.uid.toString()}', Get.find<HomeController>().loggedInUserLastName);
            GetStorage().write('email${auth.currentUser!.uid.toString()}', Get.find<HomeController>().loggedInUserEmail);
            Get.log('Current User id is ---------------${GetStorage().read(auth.currentUser!.uid.toString())}');
            Get.log('Current User First Name is --------------- ${GetStorage().read('FirstName${auth.currentUser!.uid.toString()}')}');
            Get.log('Current User Last Name  is --------------- ${GetStorage().read('LastName${auth.currentUser!.uid.toString()}')}');
            Get.log('Current User Email  is --------------- ${GetStorage().read('email${auth.currentUser!.uid.toString()}')}');
            CustomToast.successToast(message: "Login Successful");
            Get.offAll(HomeScreen());
            emailControllerLogin.clear();
            passwordControllerLogin.clear();
          }).onError((error, stackTrace) {
            Get.back();
            Get.log("ye error hai ${error.toString()}");
            CustomToast.failToast(message: "Unsuccessful Login");
          });
          //isLoading;
          // CustomToast.successToast(message: "Login Successful");
        } catch (e) {
          Get.log(e.toString());
          CustomToast.failToast(message: e.toString());
          //isLoading = false;
          //isLoading = false;
          // Get.showSnackbar(GetSnackBar(
          //       message: e.toString(),
          //       snackStyle: SnackStyle.FLOATING,
          //       backgroundColor: Colors.red,
          //       duration: const Duration(seconds: 3),
          //     ));
          // CustomToast.failToast(message: e.toString());
        }
      }
    });
  }

  checkConnectionSplash() {
    connectionService.checkConnection().then((internet) {
      if (!internet) {
        CustomToast.failToast(
            message:
                "Check your internet connection you are not Connected to Internet");
        // Get.showSnackbar(const GetSnackBar(
        //   message: "Check your internet connection you are not Connected to Internet",
        //   snackStyle: SnackStyle.FLOATING,
        //   backgroundColor: Colors.red,
        //   duration: Duration(seconds: 3),
        // ));
        //CustomToast.failToast(message: "Check your internet connection you are not Connected to Internet");
        // Get.showSnackbar(const GetSnackBar(
        //   message:  "Check your internet connection you are not Connected to Internet",snackStyle:SnackStyle.FLOATING,
        //   backgroundColor: MyColors.red500,
        //   duration: Duration(seconds: 3),
        // ));
        Get.offAll(() => SignUpScreen());
      } else {
        Get.off(LoginScreen());
        // Get.log("Access token is from Auth is ${GetStorage().read("accessToken")}");
        // GetStorage().read("accessToken")==null?Get.to(onBoardingScreen()):Get.to(BottomNavigation());
      }
    });
  }
}
