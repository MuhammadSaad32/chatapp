import 'package:chat_app/ui/values/my_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser extends StatelessWidget {
  Query<Map<String, dynamic>> collection = FirebaseFirestore.instance
      .collection("chat")
      .where('id', isNotEqualTo: FirebaseAuth.instance.currentUser!.uid);
   ChatUser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.primaryColor,
      ),
      //body: StreamBuilder(builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {  },),
    );
  }
}
