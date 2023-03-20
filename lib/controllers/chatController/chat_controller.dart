import 'package:chat_app/data/models/user_details_model/user_detail.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../data/models/chatUsersModel/chat_user_model.dart';
import '../../ui/widgets/toast.dart';

class ChatController extends GetxController {
  final auth = FirebaseAuth.instance;
  final fireStore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  int unreadMessages = 0;
  File? imageFile;
  double? lat;
  double? long;
  List<String> myLocation = [];
  //String rId = '';
  String groupID = '';
  String Status = '';
  List<QueryDocumentSnapshot> messagesList = [];
  TextEditingController chatFieldController = TextEditingController();

  sendMessage(
      {required String groupID,
      required int type,
      required String senderId,
      required String receiverId,
      required String receiverFName,
      required String receiverLName,
      required String messageContent,
      required String messageId,
      required String timeStamp,
      required bool readStatus,
      //required bool delivered,
      //required String userStatus,
      String duration = ""}) {
    fireStore
        .collection('chat')
        .doc(groupID)
        .collection(groupID)
        .doc(messageId)
        .set({
      'message': messageContent,
      'sender': senderId,
      'receiver': receiverId,
      'receiverFName': receiverFName,
      'receiverLName': receiverLName,
      'timeStamp': timeStamp,
      'messageId': messageId,
      'messageType': type,
      'readStatus': readStatus,
      //'userStatus': userStatus,
      'duration': duration
    });
    MessageModel messageModel = MessageModel(
        type: type,
        messageContent: messageContent,
        timestamp: timeStamp,
        messageId: messageId,
        currentID: senderId,
        receiverID: receiverId,
        receiverFName: receiverFName,
        receiverLName: receiverLName,
        //userStatus: userStatus,
        duration: duration,
        readStatus: readStatus);
  }

  sendMessage1(
      {required String groupID,
      required int type,
      required String senderId,
      required String receiverId,
      required String receiverFName,
      required String receiverLName,
      required String messageContent,
      required String messageId,
      required String timeStamp,
      required bool readStatus,
      //required bool delivered,
      //required String userStatus,
      String duration = ""}) {
    fireStore
        .collection('chatRoom')
        .doc(groupID)
        .collection('ChatUsers')
        .doc(auth.currentUser!.uid.toString())
        .collection('message')
        .doc(messageId)
        .set({
      'message': messageContent,
      'sender': senderId,
      'receiver': receiverId,
      'receiverFName': receiverFName,
      'receiverLName': receiverLName,
      'timeStamp': timeStamp,
      'messageId': messageId,
      'messageType': type,
      'readStatus': readStatus,
      //'userStatus': userStatus,
      'duration': duration
    });
    MessageModel messageModel = MessageModel(
        type: type,
        messageContent: messageContent,
        timestamp: timeStamp,
        messageId: messageId,
        currentID: senderId,
        receiverID: receiverId,
        receiverFName: receiverFName,
        receiverLName: receiverLName,
        //userStatus: userStatus,
        duration: duration,
        readStatus: readStatus);
  }

  sendMessage2(
      {required String groupID,
      required int type,
      required String senderId,
      required String receiverId,
      required String receiverFName,
      required String receiverLName,
      required String messageContent,
      required String messageId,
      required String timeStamp,
      required bool readStatus,
      //required bool delivered,
      //required String userStatus,
      String duration = ""}) {
    fireStore
        .collection('chatRoom')
        .doc(groupID)
        .collection('ChatUsers')
        .doc(receiverId)
        .collection('message')
        .doc(messageId)
        .set({
      'message': messageContent,
      'sender': senderId,
      'receiver': receiverId,
      'receiverFName': receiverFName,
      'receiverLName': receiverLName,
      'timeStamp': timeStamp,
      'messageId': messageId,
      'messageType': type,
      'readStatus': readStatus,
      //'userStatus': userStatus,
      'duration': duration
    });
    MessageModel messageModel = MessageModel(
        type: type,
        messageContent: messageContent,
        timestamp: timeStamp,
        messageId: messageId,
        currentID: senderId,
        receiverID: receiverId,
        receiverFName: receiverFName,
        receiverLName: receiverLName,
        //userStatus: userStatus,
        duration: duration,
        readStatus: readStatus);
  }

  // sendMessage({required String currentUserId,required String groupChatId,required String sendToUserID, required String content, required int type}) {
  //   DocumentReference documentReference = fireStore
  //       .collection('message')
  //       .doc(groupChatId)
  //       .collection(groupChatId)
  //       .doc(DateTime.now().millisecondsSinceEpoch.toString());
  //   // rId = sendToUserID;
  //   MessageChat messageChat = MessageChat(
  //     idFrom: currentUserId,
  //     idTo: sendToUserID,
  //     timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
  //     content: content,
  //     type: type,
  //   );
  //   //Get.log("receiver is $rId");
  // }
  // static Future<void> updateMessageReadStatus(MessageModel message) async {
  //   FirebaseFirestore.instance
  //       .collection('chats/${getConversationID(message.fromId)}/messages/')
  //       .doc(message.sent)
  //       .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  // }
  isChatRoomIsAvailAble() async {
    final CollectionReference collectionRef =
        FirebaseFirestore.instance.collection("chatRoom");

    final QuerySnapshot collectionSnapshot = await collectionRef.limit(1).get();
    print("${collectionSnapshot.size}");
  }

  Stream<QuerySnapshot<Object?>?>? getAllMessages(String groupChatId) {
    // isChatRoomIsAvailAble();
    return fireStore
        .collection('chatRoom')
        .doc(groupChatId)
        .collection('ChatUsers')
        .doc(auth.currentUser!.uid)
        .collection('message')
        .orderBy('timeStamp')
        //.limit(limit)
        .snapshots();

    // return collectionSnapshot.docs.isNotEmpty;
    //  fireStore.collection("chatRoom").limit(1).get().then((value) {
    //    print("value   ${value.size}");
    //    if (value.docs.isNotEmpty) {
    //      return fireStore
    //          .collection('chatRoom')
    //          .doc(groupID)
    //          .collection('ChatUsers')
    //          .doc(auth.currentUser!.uid)
    //          .collection('message')
    //          .orderBy('timeStamp')
    //          .snapshots();
    //      return value;
    //    } else {
    //      print("no sRT");
    //      return const Center(
    //        child: Text('No Messages Here yet...............'),
    //      );
    //    }
    //  });
    //  // if(data.) {
    //  //   print("no sRT");
    //  //  return null;
    //  // }
    //  //   else{
    //  //   return data;
    //  // }
    //  ;
  }

  getUnreadMessageLength({required String groupChatId}) {
    return fireStore
        .collection('chatRoom')
        .doc(groupChatId)
        .collection('ChatUsers')
        .doc(auth.currentUser!.uid)
        .collection('message')
        .where('receiver', isEqualTo: auth.currentUser!.uid.toString())
        .where('readStatus', isEqualTo: false)
        .get()
        .then((value) {
      unreadMessages = value.docs.length;
      Get.log('Unread Message Length is $unreadMessages');
      //return unreadMessages;
    });

    //data = unreadMessages as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  Stream<QuerySnapshot> getLastMessage(String groupChatId) {
    return fireStore
        .collection('chatRoom')
        .doc(groupChatId)
        .collection('ChatUsers')
        .doc(auth.currentUser!.uid)
        .collection('message')
        .orderBy('timeStamp', descending: true)
        .limit(1)
        // .limit(1)
        .snapshots();
  }

  deleteChat({required String groupId}) async {
   final CollectionReference messagesRef =fireStore
        .collection('chatRoom')
        .doc(groupId)
        .collection('ChatUsers')
        .doc(auth.currentUser!.uid)
        .collection('message');

    await messagesRef.get().then((value){
      for (var element in value.docs) {
        messagesRef.doc(element.id).delete();
      }

    });
  }

  deleteSingleMessage({required String groupId, required String messageId}) {
    return fireStore
        .collection('chatRoom')
        .doc(groupId)
        .collection('ChatUsers')
        .doc(auth.currentUser!.uid)
        .collection('message')
        .doc(messageId)
        .delete();
  }

  updateMessageReadStatus(String groupChatId, dynamic userMap) async {
    //Get.log("message time stamp is ${message.timestamp}");

    final CollectionReference collection = fireStore
        .collection('chatRoom')
        .doc(groupChatId)
        .collection('ChatUsers')
        .doc(userMap["id"])
        .collection('message');
    await collection
        .where('readStatus', isEqualTo: false)
        .get()
        .then((snapshot) async {
      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.update({"readStatus": true});
      }
    });
  }

  UploadTask uploadImage(File image, String fileName) {
    Reference reference = storage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  UploadTask uploadAudio(var audioFile, String fileName) {
    Reference reference = storage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(audioFile);
    return uploadTask;
  }

  getCurrentLatLng() async {
    var permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      CustomToast.failToast(message: "Location permission is denied");
    } else {
      await Geolocator.getCurrentPosition().then((value) {
        if (lat == null && long == null) {
          lat = value.latitude;
          long = value.longitude;
          myLocation = [lat.toString(), long.toString()];
        }
        print("lat is $lat");
        print("Long issss is $long");
        print("My location is  $myLocation");
        //sendButton(mesContent: myLocation.toString(), type: MessageType.location);
        //getHomeData(value.latitude, value.longitude);
      });
    }
  }

  // Stream getMessages({required String id, String? senderEmail}) async* {
  //   //Get.log("Current User Id is ${auth.currentUser!.uid}");
  //   //Get.log("Key Value from get is ${GetStorage().read('key ${auth.currentUser!.uid}')}");
  //   messagesList.clear();
  //   // QuerySnapshot senderEmailVerification = await fireStore.collection('Users')
  //   //     .doc(id)
  //   //     .collection('Messages')
  //   //     .get();
  //   // for (int i = 0; i < senderEmailVerification.docs.length; i++){
  //   //
  //   // }
  //   QuerySnapshot messages = await fireStore
  //       .collection('Users')
  //       .doc(id)
  //       .collection('Messages')
  //       //.where('senderEmail',isEqualTo: auth.currentUser!.email)
  //       .get();
  //   for (int i = 0; i < messages.docs.length; i++) {
  //     final v = messages.docs[i];
  //     //Get.log(" Messages are ${v['senderEmail']}");
  //     messagesList.add(v['message']);
  //     //Get.log(" Messages List is  $messagesList");
  //     //Get.log(" Messages List length  ${messagesList.length}");
  //   }
  //   // else{
  //   //   Get.log("Something went wrong");
  //   // }
  // }

  // addMessageToDb() async {
  //   QuerySnapshot querySnapshot = await fireStore.collection('Users').get();
  //   // for (int i = 0; i < querySnapshot.docs.length; i++) {
  //   //   final v = querySnapshot.docs[i];
  //   //   // Get.log('Documents in User Collection are ${v.id}');
  //   // }
  //   await fireStore.collection('Users').doc(rId).collection('Messages').add({
  //     'message': chatFieldController.text.toString(),
  //     'senderEmail': GetStorage().read('key ${auth.currentUser!.uid}')
  //   }).then((value) => {
  //         Get.showSnackbar(const GetSnackBar(
  //           message: "Message Added Successfully",
  //           snackStyle: SnackStyle.FLOATING,
  //           backgroundColor: Colors.green,
  //           duration: Duration(seconds: 3),
  //         ))
  //       });
  //   //Get.log("Email ID added To db is  ${GetStorage().read('key ${auth.currentUser!.uid}')}");
  // }
@override
  void onInit() {
   getCurrentLatLng();
    super.onInit();
  }
}

class MessageType {
  static const text = 0;
  static const image = 1;
  static const audio = 2;
  static const location = 3;
  static const video = 4;
}
