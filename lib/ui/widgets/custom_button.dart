import 'package:chat_app/ui/values/my_colors.dart';
import 'package:flutter/cupertino.dart';
import '../values/dimens.dart';
import '../values/ui_size_config.dart';

class CustomButton extends StatelessWidget {
  String text;
  VoidCallback function;
  Color? textColor;
  Color? buttonColor;
  double? height;
  double? fontSize;
  double? width;
  CustomButton({
    required this.text,
    required this.function,
    this.textColor,
    this.buttonColor,
    this.height,
    this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return GestureDetector(
      onTap: function,
      child: Container(
        height: height ?? getHeight(50),
        width: width??getWidth(double.infinity),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: buttonColor?? MyColors.primaryColor,
        ),
        child: Center(
          child:Text(
            text,style:TextStyle(
              color: textColor?? MyColors.white,
              fontSize: fontSize??Dimens.size16,
              fontWeight: FontWeight.w500


          ),
          ),
        ),
      ),
    );
  }
}