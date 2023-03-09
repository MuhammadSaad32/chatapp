import 'package:flutter/material.dart';

import '../values/dimens.dart';
import '../values/my_colors.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  static successToast({required String message}) {
    return Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.green,
      gravity: ToastGravity.CENTER,
      fontSize: Dimens.size14,
    );
  }

  static failToast({required String message}) {
    return Fluttertoast.showToast(
      msg: message,
      backgroundColor: MyColors.red500,
      gravity: ToastGravity.CENTER,
      fontSize: Dimens.size14,
    );
  }
}