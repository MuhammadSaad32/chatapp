import 'package:chat_app/controllers/homeController/home_controller.dart';
import 'package:chat_app/ui/validators/validators.dart';
import 'package:chat_app/ui/widgets/custom_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../controllers/authController/auth_controller.dart';
import '../../../values/my_colors.dart';
import '../../../values/my_imgs.dart';
import '../../../values/ui_size_config.dart';
import '../../../widgets/continue_with_google.dart';
import '../../../widgets/custom_textField.dart';
import '../../home/home_screen.dart';
import '../signup/signup_screen.dart';

class LoginScreen extends StatelessWidget {
  AuthController authController = Get.put(AuthController());
  //final _formKey = GlobalKey<FormState>();
  LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: MyColors.primaryColor,
      body: GetBuilder<AuthController>(
        builder: (controller) {
          return Form(
            key: controller.loginFormKey,
            child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: getWidth(20)),
                      child: Column(
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                height: getHeight(101),
                              ),
                              // Image.asset(
                              //   MyImgs.chat,
                              //   height: getHeight(91),
                              //   width: getWidth(98),
                              // ),
                              SizedBox(
                                height: getHeight(42),
                              ),
                              Text(
                                "Welcome Back!",
                                style: TextStyle(
                                    color: MyColors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: getFont(24)),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: getHeight(51),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Email"),
                              SizedBox(
                                height: getHeight(10),
                              ),
                              CustomTextField(
                                  text: "Enter Email",
                                  length: 30,
                                  controller: Get.find<AuthController>().emailControllerLogin,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                      const BorderSide(color: Colors.white)),
                                  validator: (val){
                                    Validators.emailValidator(val!);
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                  inputFormatters: FilteringTextInputFormatter.singleLineFormatter),
                              SizedBox(
                                height: getHeight(10),
                              ),
                              const Text("Password"),
                              SizedBox(
                                height: getHeight(10),
                              ),
                              CustomTextField(
                                  text: "Enter Password",
                                  length: 30,
                                  suffixOnTap: (){
                                    controller.hidePassLogin.value = !controller.hidePassLogin.value;
                                    controller.update();
                                  },
                                  suffixIcon: controller.hidePassLogin.value
                                      ?const Icon(Icons.visibility_off)
                                      : const Icon(Icons.visibility),
                                  obscureText: controller.hidePassLogin.value,
                                  controller: controller.passwordControllerLogin,
                                  validator: (val){
                                    Validators.passwordValidator(val!);
                                  },
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                      const BorderSide(color: Colors.white)),
                                  keyboardType: TextInputType.text,
                                  inputFormatters: FilteringTextInputFormatter.singleLineFormatter),
                              SizedBox(
                                height: getHeight(14),
                              ),
                              Align(
                                  alignment: Alignment.bottomRight,
                                  child: GestureDetector(
                                    onTap: (){
                                      // Get.to(ForgotPassword());
                                    },
                                    child: Text(
                                      "forgot password?",
                                      style: TextStyle(
                                          color: MyColors.white,
                                          decoration: TextDecoration.underline,
                                          fontSize: getFont(12),
                                          fontWeight: FontWeight.w400,
                                          fontFamily: "Ubuntu"
                                      ),
                                    ),
                                  )),
                              SizedBox(
                                height: getHeight(56),
                              ),
                              CustomButton(
                                text: "Login",
                                buttonColor: MyColors.white,
                                textColor: MyColors.primaryColor,
                                function: ()async{
                                  Get.find<AuthController>().onLoginButton();
                                  //await Get.find<AuthController>().showLoaderDialog(context);
                                 // print("Current User id from login page is ${Get.find<HomeController>().getCurrentUserID()}");
                                 //  if(_formKey.currentState!.validate()){
                                 //    Get.find<AuthController>().loginUser(mail:Get.find<AuthController>().emailControllerLogin.text.trim(),
                                 //    pass: Get.find<AuthController>().passwordControllerLogin.text.trim(),);
                                 //    //Navigator.pop(context);
                                 //    // Get.find<HomeController>().getAllUsers();
                                 //  }

                                  // Get.log("123333");
                                  // controller.checkConnectionSplash();
                                  // controller.login();
                                },
                              ),
                              SizedBox(
                                height: getHeight(89),
                              ),
                              const GoogleRowWidget(),
                              SizedBox(
                                height: getHeight(35),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: RichText(
                                  text: TextSpan(
                                      text: "Don’t have an account, ",
                                      style: TextStyle(
                                          color: MyColors.white,
                                          // decoration: TextDecoration.underline,
                                          fontSize: getFont(15),
                                          fontWeight: FontWeight.w400,
                                          fontFamily: "Ubuntu"
                                      ),
                                      children:  [
                                        TextSpan(
                                            text:"Sign Up ",
                                            recognizer: TapGestureRecognizer()..onTap=(){
                                              authController.confirmPasswordController.clear();
                                              authController.firstNameController.clear();
                                              authController.lastNameController.clear();
                                              authController.emailController.clear();
                                              authController.passwordController.clear();
                                              Get.to(SignUpScreen());
                                            },

                                            style: TextStyle(
                                                color: MyColors.white,
                                                decoration: TextDecoration.underline,
                                                fontSize: getFont(15),
                                                fontWeight: FontWeight.w400,
                                                fontFamily: "Ubuntu"
                                            )),
                                        TextSpan(
                                            text:"now.",
                                            style: TextStyle(
                                                color: MyColors.white,
                                                // decoration: TextDecoration.underline,
                                                fontSize: getFont(15),
                                                fontWeight: FontWeight.w400,
                                                fontFamily: "Ubuntu"
                                            )),


                                      ]

                                  ),
                                ),
                              ),
                            ],
                          )
              ]
                      ),
                    ),
            ),
          );
        }
      ));
          }
}
