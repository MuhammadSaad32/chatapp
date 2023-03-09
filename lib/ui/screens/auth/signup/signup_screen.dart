import 'package:chat_app/controllers/authController/auth_controller.dart';
import 'package:chat_app/ui/validators/validators.dart';
import 'package:chat_app/ui/values/dimens.dart';
import 'package:chat_app/ui/values/ui_size_config.dart';
import 'package:chat_app/ui/widgets/custom_textField.dart';
import 'package:chat_app/ui/widgets/toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../values/my_colors.dart';
import '../../../widgets/continue_with_google.dart';
import '../../../widgets/custom_button.dart';
import '../login/login_screen.dart';

class SignUpScreen extends StatelessWidget {
  AuthController authController = Get.put(AuthController());
  //final _formKey = GlobalKey<FormState>();

  SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: MyColors.primaryColor,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: MyColors.primaryColor,
        title: const Text(
          "SignUp Screen",
        ),
        centerTitle: true,
        //  fontWeight: FontWeight.normal
      ),
      body: GetBuilder<AuthController>(
        builder: (controller) {
          return SingleChildScrollView(
            child: Form(
              key: controller.signUpFormKey,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: getWidth(20)),
                child: Column(
                  children: [
                    SizedBox(
                      height: getHeight(20),
                    ),
                    Center(
                      child: Text(
                        "Create your account",
                        style: TextStyle(
                            color: MyColors.black,
                            fontSize: getFont(24),
                            fontWeight: FontWeight.w500,
                            fontFamily: "Ubuntu"),
                      ),
                    ),
                    SizedBox(
                      height: getHeight(20),
                    ),
                    SizedBox(
                      height: getHeight(105),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "First Name",
                                ),
                                SizedBox(
                                  height: getHeight(10),
                                ),
                                CustomTextField(
                                    text: "First Name",
                                    length: 30,
                                    validator: (val) {
                                      return Validators.firstNameValidation(val!);
                                    },
                                    controller: controller.firstNameController,
                                    border: const OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: MyColors.red500)),
                                    keyboardType: TextInputType.text,
                                    inputFormatters:
                                        FilteringTextInputFormatter.allow(
                                            RegExp('[a-zA-Z- ]'))),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: getWidth(10),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Last Name",
                                ),
                                SizedBox(
                                  height: getHeight(10),
                                ),
                                CustomTextField(
                                    text: "Last Name",
                                    length: 30,
                                    validator: (val) {
                                      return Validators.lastNameValidation(val!);
                                    },
                                    controller: controller.lastNameController,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide:
                                            const BorderSide(color: Colors.red)),
                                    keyboardType: TextInputType.text,
                                    inputFormatters:
                                        FilteringTextInputFormatter.allow(
                                            RegExp('[a-zA-Z- ]'))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Email"),
                        SizedBox(
                          height: getHeight(10),
                        ),
                        CustomTextField(
                            text: "Email",
                            length: 30,
                            validator: (val) {
                              return Validators.emailValidator(val!);
                            },
                            controller: controller.emailController,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white)),
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters:
                                FilteringTextInputFormatter.singleLineFormatter)
                      ],
                    ),
                    SizedBox(
                      height: getHeight(10),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Password"),
                        SizedBox(
                          height: getHeight(10),
                        ),
                        CustomTextField(
                            text: "Password",
                            length: 30,
                            validator: (val) {
                              return Validators.passwordValidator(val!);
                            },
                            suffixOnTap: () {
                              controller.hidePassword.value= !controller.hidePassword.value;
                              controller.update();
                            },
                            controller: controller.passwordController,
                            suffixIcon: controller.hidePassword.value
                                 ?const Icon(Icons.visibility_off)
                                : const Icon(Icons.visibility),
                            obscureText: controller.hidePassword.value,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white)),
                            keyboardType: TextInputType.text,
                            inputFormatters:
                                FilteringTextInputFormatter.singleLineFormatter)
                      ],
                    ),
                    SizedBox(
                      height: getHeight(10),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Confirm Password"),
                        SizedBox(
                          height: getHeight(10),
                        ),
                        CustomTextField(
                            text: "Confirm Password",
                            length: 30,
                            obscureText: controller.hideConfirmPass.value,
                            validator: (val) {
                              return Validators.passwordValidator(val!);
                            },
                            suffixOnTap: (){
                              controller.hideConfirmPass.value=!controller.hideConfirmPass.value;
                              controller.update();
                            },
                            controller: controller.confirmPasswordController,
                            suffixIcon: controller.hideConfirmPass.value
                                ?const Icon(Icons.visibility_off)
                                : const Icon(Icons.visibility),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.red)),
                            keyboardType: TextInputType.text,
                            inputFormatters:
                                FilteringTextInputFormatter.singleLineFormatter)
                      ],
                    ),
                    SizedBox(
                      height: getHeight(100),
                    ),
                    CustomButton(
                      function: () async {
                        if(controller.passwordController.text==controller.confirmPasswordController.text) {
                          await controller.onSignUpButton();
                        }
                        else{
                          CustomToast.failToast(
                              message: "Password Does Not Match");
                        }
                        // if (_formKey.currentState!.validate()) {
                        //   if (authController.passwordController.text.trim() ==
                        //       authController.confirmPasswordController.text
                        //           .trim()) {
                        //     await authController.registerUser(
                        //       mail: authController.emailController.text.trim(),
                        //       fName: authController.firstNameController.text,
                        //       lName: authController.lastNameController.text,
                        //       pass: authController.passwordController.text.trim(),
                        //     );
                        //   } else {
                        //     CustomToast.failToast(message: "Password not Match");
                        //   }
                        //   // Get.off(LoginScreen());
                        //
                        //
                      },
                      text: "Create Account",
                      buttonColor: Colors.white,
                      textColor: MyColors.primaryColor,
                    ),
                    SizedBox(
                      height: getHeight(30),
                    ),
                    const GoogleRowWidget(),
                    SizedBox(
                      height: getHeight(35),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: RichText(
                        text: TextSpan(
                            text: "Already have an account, ",
                            style: TextStyle(
                                color: MyColors.white,
                                // decoration: TextDecoration.underline,
                                fontSize: getFont(15),
                                fontWeight: FontWeight.w400,
                                fontFamily: "Ubuntu"),
                            children: [
                              TextSpan(
                                  text: "Login ",
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                    controller.emailControllerLogin.clear();
                                    controller.passwordControllerLogin.clear();
                                      Get.to(LoginScreen());
                                    },
                                  style: TextStyle(
                                      color: MyColors.white,
                                      decoration: TextDecoration.underline,
                                      fontSize: getFont(15),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "Ubuntu")),
                              TextSpan(
                                  text: "now.",
                                  style: TextStyle(
                                      color: MyColors.white,
                                      // decoration: TextDecoration.underline,
                                      fontSize: getFont(15),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "Ubuntu")),
                            ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
