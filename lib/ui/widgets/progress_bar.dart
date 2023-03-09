import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../values/my_colors.dart';

class ProgressBar extends StatelessWidget{

  ProgressBar();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        backgroundColor: MyColors.primaryColor,
        color: MyColors.white,
        strokeWidth: 4,
      ),
    );
  }

}
