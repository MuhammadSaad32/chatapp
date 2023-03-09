
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dimens.dart';
import 'my_colors.dart';
import 'my_fonts.dart';




class Styles {
  static final appTheme = _baseTheme.copyWith(
    iconTheme: const IconThemeData(
      color: MyColors.black,
      size: Dimens.size20,
    ),

    textTheme: _baseTextTheme,
    accentTextTheme: _accentTextTheme,
    cardTheme: _baseTheme.cardTheme.copyWith(
      margin: EdgeInsets.zero,
    ),
    textSelectionTheme: _baseTheme.textSelectionTheme.copyWith(
      cursorColor: _colorScheme.secondary,
      selectionHandleColor: _colorScheme.secondary,

    ),



    appBarTheme: AppBarTheme(backgroundColor: _colorScheme.primary),
   // primaryTextTheme: ,
    scrollbarTheme: ScrollbarThemeData(
        isAlwaysShown: true,
        showTrackOnHover: true,
        interactive: true,

        trackColor: MaterialStateProperty.all(MyColors.green100 ),
        trackBorderColor: MaterialStateProperty.all(MyColors.yellow),
        thickness: MaterialStateProperty.all(5),
        thumbColor: MaterialStateProperty.all(MyColors.primaryColor),
        radius: Radius.circular(10),
        minThumbLength: 10),
  );



  static final secondaryTextTheme = _baseTextTheme.apply(
    displayColor: MyColors.white,
    bodyColor: MyColors.white200,
    fontFamily: MyFonts.roboto,
  );

  static final onSecondaryTextTheme = _baseTextTheme.apply(
    displayColor: MyColors.black,
    bodyColor: MyColors.black,
    fontFamily: MyFonts.roboto,
  );

  static const _colorScheme = ColorScheme.light(
    primary: MyColors.primaryColor,
    primaryVariant: MyColors.buttonColor,
    secondary: MyColors.black,
    secondaryVariant: MyColors.grey,
    onPrimary: MyColors.white,
    onSecondary: MyColors.parpal,
    onBackground: MyColors.grey200,

  );

  static final _baseTheme = ThemeData.from(
    colorScheme: _colorScheme,
    textTheme: Typography
        .material2018()
        .black
        .apply(
      fontFamily: MyFonts.roboto,
      displayColor: _colorScheme.secondary,
      bodyColor: _colorScheme.secondary,
    ),
  );

  static final _baseTextTheme = _baseTheme.textTheme.copyWith(
    headline1: _baseTheme.textTheme.headline1!.copyWith(
      color: MyColors.white,
      fontSize: 18,
      height: 1.5,
      fontWeight: FontWeight.w500,
           fontFamily: MyFonts.roboto,
    ),
    headline2: _baseTheme.textTheme.headline2!.copyWith(
      color: MyColors.black,
      fontSize: 20,
      height: 1.5,
      fontWeight: FontWeight.w500,
      fontFamily: MyFonts.roboto,
    ),
    headline3: _baseTheme.textTheme.headline3!.copyWith(
      color: MyColors.darkBlue,
      fontSize: 20,
      height: 1.5,
      fontWeight: FontWeight.w500,
      fontFamily: MyFonts.roboto,
    ),
    headline4: _baseTheme.textTheme.headline4!.copyWith(
      color: MyColors.black,
      fontSize: 18,
      height: 1.5,
      fontWeight: FontWeight.w500,
      fontFamily: MyFonts.roboto,

    ),
    headline5: _baseTheme.textTheme.headline5!.copyWith(
      fontSize: 16,
      color: MyColors.darkBlue,
      height: 1.5,
      fontWeight: FontWeight.w500,
      fontFamily: MyFonts.roboto,
    ),
    headline6: _baseTheme.textTheme.headline6!.copyWith(
      fontSize: 14,
      color: MyColors.darkBlue,
      height: 1.5,
      fontWeight: FontWeight.w500,
      fontFamily: MyFonts.roboto,
    ),
    bodyText1: _baseTheme.textTheme.bodyText1!.copyWith(
        fontSize: 16,
        color: MyColors.black,
        height: 1.5,
        fontWeight: FontWeight.w500,
      fontFamily: MyFonts.roboto,
    ),
    bodyText2: _baseTheme.textTheme.bodyText2!.copyWith(
        fontSize: 14,
        color: MyColors.black,
        height: 1.5,
        fontWeight: FontWeight.w500,
      fontFamily: MyFonts.roboto,
    ),

    subtitle1: _baseTheme.textTheme.subtitle1!.copyWith(
        fontSize: 12,
        color: MyColors.black,
        height: 1.5,
        fontWeight: FontWeight.w400,
      fontFamily: MyFonts.roboto,
    ),
    subtitle2: _baseTheme.textTheme.subtitle2!.copyWith(
        fontSize: 12,
        color: MyColors.darkBlue,
        //  decoration: TextDecoration.underline,
        height: 1.5,
        fontWeight: FontWeight.w500,
      fontFamily: MyFonts.roboto,
    ),
    caption: _baseTheme.textTheme.caption!.copyWith(
      fontSize: 10,
      color: MyColors.grey,
      height: 1.5,
      fontFamily: MyFonts.roboto,
    ),
    overline: _baseTheme.textTheme.overline!.copyWith(
      fontSize: 8,
      fontFamily: MyFonts.roboto,
      color: MyColors.grey,
      height: 1.5,
    ),
  );

  static final _accentTextTheme = _baseTextTheme.apply(
    displayColor: _colorScheme.secondary,
    bodyColor: _colorScheme.secondary,
  );

  Styles._();
}