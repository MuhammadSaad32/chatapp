import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  String currentID;
  String receiverID;
  String receiverFName;
  String receiverLName;
  String timestamp;
  String messageId;
  String messageContent;
  String? duration;
  //String? fileName;
  bool readStatus;
  int type;

  MessageModel({
    required this.currentID,
    required this.receiverID,
    required this.receiverFName,
    required this.receiverLName,
    required this.timestamp,
    required this.messageContent,
    required this.messageId,
    //required this.delivered,
    this.duration,
    //this.fileName,
    required this.readStatus,
    //required this.userStatus,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      "sender": currentID,
      "receiver": receiverID,
      "receiverFName": receiverFName,
      "receiverLName": receiverLName,
      "timeStamp": timestamp,
      "duration": duration,
      "messageId": messageId,
      "readStatus": readStatus,
     // "fileName": fileName,
      //"userStatus": userStatus,
      "message": messageContent,
      "messageType": type,
    };
  }

  factory MessageModel.fromJson(DocumentSnapshot doc) {
    String currentID = doc.get("sender");
    String receiverID = doc.get("receiver");
    String receiverFName = doc.get("receiverFName");
    String receiverLName = doc.get("receiverLName");
    String messageContent = doc.get("message");
    String timestamp = doc.get("timeStamp") ?? DateTime.now();
    String messageId = doc.get("messageId");
    bool readStatus = doc.get("readStatus");
   // String fileName = doc.get("fileName");
    String duration = doc.get("duration");
    int type = doc.get("messageType");
    return MessageModel(
        //userStatus: userStatus,
        messageId: messageId,
        readStatus: readStatus,
        type: type,
        duration: duration,
       // fileName: fileName,
        currentID: currentID,
        receiverID: receiverID,
        receiverFName: receiverFName,
        receiverLName: receiverLName,
        messageContent: messageContent,
        timestamp: timestamp);
  }
}
