import 'package:flutter/cupertino.dart';

import '../values/my_colors.dart';
import '../values/my_imgs.dart';
import '../values/ui_size_config.dart';

class GoogleRowWidget extends StatelessWidget {
  const GoogleRowWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getHeight(50),
      decoration: BoxDecoration(
          color: MyColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MyColors.black)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Image.asset(MyImgs.google,height: getHeight(24),width: getWidth(24),),
          Text("Continue with Google",style: TextStyle(color: MyColors.black,fontSize: getFont(18),fontWeight: FontWeight.w400),)

        ],
      ),
    );
  }
}