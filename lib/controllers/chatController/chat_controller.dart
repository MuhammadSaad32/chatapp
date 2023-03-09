import 'package:chat_app/data/models/user_details_model/user_detail.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../data/models/chatUsersModel/chat_user_model.dart';

class ChatController extends GetxController {
  final auth = FirebaseAuth.instance;
  final fireStore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  int unreadMessages = 0;
  //String rId = '';
  String groupID = '';
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
  Stream<QuerySnapshot> getAllMessages(String groupChatId) {
    return fireStore
        .collection('chat')
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy('timeStamp')
        //.limit(limit)
        .snapshots();
  }

  getUnreadMessageLength({required String groupChatId}) {
    return fireStore
        .collection('chat')
        .doc(groupChatId)
        .collection(groupChatId)
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
    return FirebaseFirestore.instance
        .collection('chat')
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy('timeStamp', descending: true)
        .limit(1)
        // .limit(1)
        .snapshots();
  }
  deleteSingleMessage({required String groupId, required String messageId}){
    return fireStore.collection('chat').doc(groupId).collection(groupId).doc(messageId).delete();
  }

  updateMessageReadStatus(MessageModel message, String groupChatId) async {
    //Get.log("message time stamp is ${message.timestamp}");
    await fireStore
        .collection('chat')
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(message.messageId)
        .update({
      'readStatus': true,
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
}

class MessageType {
  static const text = 0;
  static const image = 1;
  static const audio = 2;
}
