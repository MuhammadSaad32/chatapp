import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../values/my_colors.dart';
import '../values/ui_size_config.dart';

class DialogueBox{
  DialogueBox();
  Future<bool> showExitPopup(BuildContext context) async {
    return await showDialog(
      //show confirm dialogue
      //the return value will be from "Yes" or "No" options
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit an App?'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            //return false when click on "NO"
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryColor,
            ),
            onPressed: () => SystemNavigator.pop(),
            //return true when click on "Yes"
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ??
        false; //if showDialouge had returned null, then return false
  }
  Future<bool> deleteMessage(BuildContext context,VoidCallback function) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Delete Message'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            //return false when click on "NO"
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryColor,
            ),
            onPressed: function,
            //return true when click on "Yes"
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ??
        false; //if showDialouge had returned null, then return false
  }
  Future<bool> dialogueBox(BuildContext context ) async {
    return await showDialog(
      //show confirm dialogue
      //the return value will be from "Yes" or "No" options
      context: context,
      builder: (context) => AlertDialog(
        //title: const Text('Exit App'),
        //content: const Text('Do you want to exit an App?'),
        actions: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              height: getHeight(200),
              width: double.infinity,
              decoration: BoxDecoration(
                color: MyColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: getHeight(60),
                            width: getWidth(70),
                            decoration: const BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle),
                            child: Icon(
                              Icons.description,
                              size: getHeight(30),
                              color: MyColors.white,
                            ),
                          ),
                          SizedBox(
                            height: getHeight(5),
                          ),
                          const Text("Documents")
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            height: getHeight(60),
                            width: getWidth(70),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: Icon(
                              Icons.photo_camera,
                              size: getHeight(30),
                              color: MyColors.white,
                            ),
                          ),
                          SizedBox(
                            height: getHeight(5),
                          ),
                          const Text("Photo")
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            height: getHeight(60),
                            width: getWidth(70),
                            decoration: const BoxDecoration(
                                color: Colors.deepPurpleAccent,
                                shape: BoxShape.circle),
                            child: Icon(
                              Icons.collections_bookmark,
                              size: getHeight(30),
                              color: MyColors.white,
                            ),
                          ),
                          SizedBox(
                            height: getHeight(5),
                          ),
                          const Text("Gallery")
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Container(
                            height: getHeight(60),
                            width: getWidth(70),
                            decoration: const BoxDecoration(
                                color: Colors.deepOrangeAccent,
                                shape: BoxShape.circle),
                            child: Icon(
                              Icons.headset,
                              size: getHeight(30),
                              color: MyColors.white,
                            ),
                          ),
                          SizedBox(
                            height: getHeight(5),
                          ),
                          const Text("Audio")
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            height: getHeight(60),
                            width: getWidth(70),
                            decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle),
                            child: Icon(
                              Icons.location_on,
                              size: getHeight(30),
                              color: MyColors.white,
                            ),
                          ),
                          SizedBox(
                            height: getHeight(5),
                          ),
                          const Text("Location")
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            height: getHeight(60),
                            width: getWidth(70),
                            decoration: const BoxDecoration(
                                color: Colors.lightBlue,
                                shape: BoxShape.circle),
                            child: Icon(
                              Icons.person,
                              size: getHeight(30),
                              color: MyColors.white,
                            ),
                          ),
                          SizedBox(
                            height: getHeight(5),
                          ),
                          const Text("Contact")
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ) ??
        false; //if showDialouge had returned null, then return false
  }
}