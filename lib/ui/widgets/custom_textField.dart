import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../values/my_colors.dart';

class CustomTextField extends StatelessWidget {
  final String text;
  final int? length;
  final TextInputType   keyboardType;
  final TextInputFormatter   inputFormatters;
  bool ? readonly=false;
  bool ? obscureText=false;
  final Icon ? prefixIcon;
  final Icon ? suffixIcon;
  final InputBorder ? border;
  final String ? errorText;
  final FocusNode ? focusNode;
  final String ? suffixText;
  final Color ? hintColor;
  final Function()? suffixOnTap;
  final Function()? prefixOnTap;
  final int  ?maxLine;
  TextEditingController ? controller;
  FormFieldValidator<String>? validator;
  ValueChanged<String>? onChanged;
  FormFieldSetter<String>? onSaved;
  CustomTextField({Key? key,
    this.controller,
    this.border,
    this.suffixOnTap,
    this.prefixOnTap,
    this.onSaved,
    this.maxLine,
    required this.text,
    this.validator,
    this.onChanged,
    this.errorText,
    this.readonly,
    this.focusNode,
    this.hintColor,
    this.obscureText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.length,
    required this.keyboardType,
    required this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //var theme=Theme.of(context);
    //var textTheme=theme.textTheme;
    //var mediaQuery = MediaQuery.of(context).size;

    return TextFormField(
      obscureText: obscureText==true?true : false,
      onSaved: onSaved,
      minLines: 1,
      maxLines: maxLine ?? 1,
      maxLength: length,
      cursorHeight: 25,
      focusNode: focusNode,
      validator: validator,
      style:  const TextStyle(fontSize: 16,fontWeight: FontWeight.w400),
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: <TextInputFormatter>[inputFormatters],
      textInputAction: TextInputAction.next,
      readOnly: readonly==true ? true : false,
      decoration: InputDecoration(
        errorText: errorText,
        counterText: "",
        border: border,
        hintText: text ,
        hintStyle: TextStyle(color: hintColor,fontSize: 16,fontWeight: FontWeight.w400),
        contentPadding: const EdgeInsets.only(left: 8, bottom: 10),
        prefixIcon: prefixIcon==null?null:GestureDetector(
            onTap: prefixOnTap,
            child: prefixIcon),
        suffixIcon: suffixIcon==null?null:GestureDetector(
            onTap: suffixOnTap,
            child: suffixIcon),
        suffixText: suffixText ,
        // focusColor: MyColors.white,
      ),
    );
  }
}