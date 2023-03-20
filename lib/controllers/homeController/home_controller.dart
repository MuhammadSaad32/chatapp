import 'package:chat_app/controllers/chatController/chat_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../ui/screens/auth/login/login_screen.dart';

class HomeController extends GetxController {
  final fireStore = FirebaseFirestore.instance;
  TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;
  String? currentUserID;
  String loggedInUserFirstName = "";
  String? loggedInUserLastName = "";
  String? loggedInUserEmail = "";
  String groupID = '';
  List searchResult = [];

  getCurrentUserID() async {
    currentUserID = auth.currentUser!.uid.toString();
    Get.log('Current login id is $currentUserID');
  }

  setStatus(String status) async {
    await fireStore
        .collection('Users')
        .doc(auth.currentUser!.uid.toString())
        .update({
        "status": status,
    });
  }

  Future getDataCurrentUser() async {
    await fireStore
        .collection('Users')
        .doc(auth.currentUser!.uid.toString())
        .get()
        .then((value) {
      loggedInUserFirstName = value.data()!['firstName'];
      loggedInUserLastName = value.data()!['lastName'];
      loggedInUserEmail = value.data()!['email'];
      value.data()!['password'];
      value.data()!['id'];
      Get.log("12313uhjcsd djfsd lasdcn ${value.data()!['firstName']} , "
          "${value.data()!['lastName']}, "
          "${value.data()!['email']} ,"
          " ${value.data()!['password']} ,"
          "${value.data()!['id']}");
    });
    print("name  ${loggedInUserLastName}");
  }

  Stream<QuerySnapshot> searchFireStore(
       String? textSearch) {
    if (textSearch?.isNotEmpty == true) {
      return fireStore
          .collection('Users')
          .where("lastName", arrayContains: textSearch)
          .snapshots();
    } else {
      return fireStore.collection('Users').snapshots();
    }
  }
  getLastMessageTime(
      {required BuildContext context,
        String? time,
        bool showYear = false}) {
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time!));
    final DateTime now = DateTime.now();

    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return TimeOfDay.fromDateTime(sent).format(context);
    }

    return showYear
        ? '${sent.day} ${_getMonth(sent)} ${sent.year}'
        : '${sent.day} ${_getMonth(sent)}';
  }
  static String _getMonth(DateTime date) {
    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sept';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return 'NA';
  }

  Future signOut() async {
    await auth.signOut().then((value) {
      Get.offAll(LoginScreen());
    });
  }
  @override
  void onInit() {
    Get.find<ChatController>().getCurrentLatLng();
    print("Currenrtern ${Get.find<ChatController>().myLocation}");
    super.onInit();
  }
}
