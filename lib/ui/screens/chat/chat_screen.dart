import 'package:chat_app/controllers/homeController/home_controller.dart';
import 'package:chat_app/ui/screens/home/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/controllers/chatController/chat_controller.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chat_app/data/models/chatUsersModel/chat_user_model.dart';
import 'package:chat_app/ui/values/ui_size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../../controllers/audioController/audio_controller.dart';
import '../../../data/getServices/CheckConnectionService.dart';
import '../../values/my_colors.dart';
import '../../widgets/date_format.dart';
import '../../widgets/toast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ChatScreen extends StatefulWidget {
  // String firstName;
  // String lastName;
  // String sendToUserID;
  // String groupId;
  // String currentUserID;
  dynamic userMap;
  String groupId;
  // ChatController chatController = Get.put(ChatController());
  ChatScreen({
    super.key,
    this.userMap,
    required this.groupId,
    // required this.firstName,
    // required this.lastName,
    // required this.sendToUserID,
    // required this.groupId,
    // required this.currentUserID,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  File? imageFile;
  File? audioFile;
  FirebaseAuth auth = FirebaseAuth.instance;
  AudioController audioController = Get.put(AudioController());
  bool loading = false;
  AudioPlayer audioPlayer = AudioPlayer();
  CheckConnectionService connectionService = CheckConnectionService();
  String audioURL = "";
  String recordFilePath = "";
  String imageUrl = "";
  Position? currentPosition;

  Future<void> _getCurrentPosition() async {
    //final hasPermission = await _handleLocationPermission();
    //if (!hasPermission) return;
    await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() =>  currentPosition = position);
      print("Current location is ${currentPosition}");
    }).catchError((e) {
      debugPrint(e);
    });
  }
  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void sendButton({
    required String mesContent,
    required int type,
    bool? readStatus = false,
    //String? userStatus = "Offline",
    String? duration = "",
  }) {
    if (mesContent.trim().isNotEmpty) {
      //Get.find<ChatController>().getUnreadMessageLength(groupChatId: widget.groupId);
      //Get.log("message length is ${Get.find<ChatController>().unreadMessages}");
      var uuid = const Uuid();
      Get.find<ChatController>().chatFieldController.clear();
      Get.find<ChatController>().sendMessage(
          messageContent: mesContent,
          readStatus: readStatus!,
          //userStatus: userStatus!,
          type: type,
          messageId: uuid.v1(),
          receiverFName: widget.userMap["firstName"],
          receiverLName: widget.userMap["lastName"],
          senderId: GetStorage().read(auth.currentUser!.uid.toString()),
          receiverId: widget.userMap['id'],
          groupID: widget.groupId,
          duration: duration!,
          timeStamp: DateTime.now().millisecondsSinceEpoch.toString());

      // if (listScrollController.hasClients) {
      //   listScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      // }
    } else {
      CustomToast.failToast(message: 'Nothing to send');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          leading: GestureDetector(
              onTap: () async {
                await Get.find<HomeController>().getCurrentUserID();
                await Get.find<HomeController>().getDataCurrentUser();
                Get.off(const HomeScreen());
              },
              child: const Icon(Icons.arrow_back)),
          backgroundColor: MyColors.primaryColor,
          centerTitle: true,
          title: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${widget.userMap['firstName']} ${widget.userMap['lastName']}'),
                SizedBox(
                  height: getHeight(5),
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(widget.userMap['id'])
                      .snapshots(),
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        color: MyColors.primaryColor,
                      );
                    } else {
                      if (snapshot.connectionState == ConnectionState.done ||
                          snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasError) {
                          CustomToast.failToast(
                              message: snapshot.error.toString());
                        } else {
                          return Row(
                            children: [
                              Text(
                                snapshot.data['status'],
                                style: TextStyle(fontSize: getFont(16)),
                              ),
                              SizedBox(
                                width: getWidth(4),
                              ),
                              Icon(
                                Icons.circle,
                                size: getHeight(15),
                                color: snapshot.data['status'] == 'Online'
                                    ? Colors.green
                                    : Colors.red,
                              )
                            ],
                          );
                        }
                      }
                    }
                    return const SizedBox();
                  },
                )
              ],
            ),
          ),
          actions: [GestureDetector(
              onTap: (){
                _getCurrentPosition();
              },
              child: Icon(Icons.info_outline))],
        ),
      ),
      body: Stack(children: [
        Column(
          children: [
            buildListMessage(),
            chatBottomField(),
            // Padding(
            //   padding: EdgeInsets.symmetric(horizontal: getWidth(20)),
            //   child: CustomTextField(
            //     text: "Type Your Message",
            //     prefixIcon: const Icon(Icons.attach_file_sharp),
            //     suffixIcon: const Icon(Icons.send),
            //     prefixOnTap: () {},
            //     suffixOnTap: () async {
            //       String id = (sendToUserID.hashCode +
            //               Get.find<HomeController>().currentUserID.hashCode)
            //           .toString();
            //       print("Combine id is $id ");
            //       if (Get.find<ChatController>()
            //           .chatFieldController
            //           .text
            //           .isNotEmpty) {
            //         Get.find<ChatController>().sendMessage(
            //             groupID: id,
            //             messageContent: Get.find<ChatController>()
            //                 .chatFieldController
            //                 .text
            //                 .toString(),
            //             receiverId: sendToUserID,
            //             senderId:
            //                 Get.find<HomeController>().currentUserID.toString());
            //       } else {
            //         CustomToast.failToast(
            //             message: "Nothing to Send Pleast Type Message");
            //       }
            //       // content: Get.find<ChatController>().chatFieldController.text,
            //       //     currentUserId: Get.find<HomeController>().currentUserID,
            //       //   sendToUserID: sendToUserID,
            //       //   type: 0,
            //       //   groupChatId:Get.find<HomeController>().currentUserID+sendToUserID
            //       // );
            //       // Get.log("Receiver Id is $receiverID");
            //       //await Get.find<ChatController>().addMessageToDb();
            //       //await chatController.getMessages();
            //       Get.find<ChatController>().chatFieldController.clear();
            //     },
            //     keyboardType: TextInputType.multiline,
            //     inputFormatters: FilteringTextInputFormatter.singleLineFormatter,
            //     maxLine: 3,
            //     controller: Get.find<ChatController>().chatFieldController,
            //     border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(8),
            //         borderSide: const BorderSide(color: Colors.red)),
            //   ),
            // ),
          ],
        ),
      ]),
    );
  }

  // Image Files Start Here All Code Related to sending images

  Future uploadImage() async {
    connectionService.checkConnection().then((internet) async {
      if (!internet) {
        CustomToast.failToast(message: "Not Connected to internet");
      } else {
        var upload;
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        loading = true;
        final ref = FirebaseStorage.instance
            .ref()
            .child('images')
            .child('$fileName.jgp');
        await ref.putFile(imageFile!).then((p0) {
          setState(() {
            upload = p0;
            loading = false;
          });
        });
        //imageUrl==""?const CircularProgressIndicator():SizedBox();
        imageUrl = await upload.ref.getDownloadURL();
        print(imageUrl);
        sendButton(mesContent: imageUrl, type: MessageType.image);
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(GetStorage().read(auth.currentUser!.uid.toString()))
            .collection("myUsers")
            .get()
            .then((value) {
          if (value.docs.contains(widget.userMap['id'])) {
            print("user is  available");
          } else {
            FirebaseFirestore.instance
                .collection('Users')
                .doc(GetStorage().read(auth.currentUser!.uid.toString()))
                .collection("myUsers")
                .doc(widget.userMap['id'])
                .set(
                    //     {
                    //   'email': widget.groupId,
                    //   'senderId': GetStorage().read(auth.currentUser!.uid.toString()),
                    //   'receiverId': widget.userMap['id'],
                    //   'firstName': widget.userMap['firstName'],
                    //   'lastName': widget.userMap['lastName'],
                    // }
                    widget.userMap);
          }
        });
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(widget.userMap['id'])
            .collection("myUsers")
            .get()
            .then((value) {
          if (value.docs
              .contains(GetStorage().read(auth.currentUser!.uid.toString()))) {
            print("user is  available");
          } else {
            //for (var element in value.docs) {
            FirebaseFirestore.instance
                .collection('Users')
                .doc(widget.userMap['id'])
                .collection("myUsers")
                .doc(GetStorage().read(auth.currentUser!.uid.toString()))
                .set({
              'email': auth.currentUser!.email,
              'id': auth.currentUser!.uid,
              'status': "offline",
              'password': "1234445",
              'firstName': GetStorage()
                  .read('FirstName${auth.currentUser!.uid.toString()}'),
              'lastName': GetStorage()
                  .read('LastName${auth.currentUser!.uid.toString()}'),
              // 'lastName': userDetails.lastName.toString(),
            });
            // }
          }
        });
        // await FirebaseFirestore.instance
        //     .collection("Users")
        //     .doc(Get.find<HomeController>().currentUserID.toString())
        //     .collection("myUsers")
        //     .get()
        //     .then((value) {
        //   if (value.docs.contains(widget.userMap['receiverID'])) {
        //     print("user is  available");
        //   } else {
        //     Get.log("First Name is ${widget.userMap['firstName']}");
        //     Get.log("Foiirst Name is ${widget.userMap['lastName']}");
        //     FirebaseFirestore.instance
        //         .collection('Users')
        //         .doc(Get.find<HomeController>().currentUserID.toString())
        //         .collection("myUsers").doc(widget.userMap['receiverID'])
        //         .set({
        //       'groupId': widget.userMap['groupId'],
        //       'senderId': Get.find<HomeController>().currentUserID.toString(),
        //       'receiverId': widget.userMap['receiverID'],
        //       'firstName': widget.userMap['firstName'],
        //       'lastName': widget.userMap['lastName'],
        //     });
        //   }
        // });
        // await FirebaseFirestore.instance
        //     .collection("Users")
        //     .doc(Get.find<HomeController>().currentUserID.toString())
        //     .collection("myUsers")
        //     .get().then((value) {
        //   if (value.docs.contains(Get.find<HomeController>().currentUserID.toString())) {
        //     print("user is  available");
        //   }
        //   else{
        //     //for (var element in value.docs) {
        //     FirebaseFirestore.instance
        //         .collection('Users')
        //         .doc(widget.userMap['receiverID'])
        //         .collection("myUsers").doc(Get.find<HomeController>().currentUserID.toString())
        //         .set({
        //       'groupId': widget.userMap['groupId'],
        //       'senderId': widget.userMap['receiverID'],
        //       'receiverId': Get.find<HomeController>().currentUserID.toString(),
        //       //'firstName':userDetails.firstName.toString(),
        //       'firstName': Get.find<HomeController>().loggedInUserFirstName.toString(),
        //       'lastName':Get.find<HomeController>().loggedInUserLastName.toString(),
        //       // 'lastName': userDetails.lastName.toString(),
        //     });
        //     // }
        //   }
        // });
      }
    });
  }

  Future getImageGallery() async {
    ImagePicker imagePicker = ImagePicker();
    //PickedFile? pickedFile;
    await imagePicker.getImage(source: ImageSource.gallery).then((xFile) async {
      if (xFile != null) {
        imageFile = File(xFile.path);
        print("Image File is $imageFile");
        setState(() {
          loading = true;
        });
        uploadImage();
      }
    });
    // if (pickedFile != null) {
    //   imageFile = File(pickedFile.path);
    //   if (imageFile != null) {
    //     print("12345566566656");
    //     uploadFile();
    //   }
    // }
  }

  Future getImageCamera() async {
    ImagePicker imagePicker = ImagePicker();
    //PickedFile? pickedFile;
    await imagePicker.getImage(source: ImageSource.camera).then((xFile) async {
      if (xFile != null) {
        imageFile = File(xFile.path);
        print("Image File is $imageFile");
        setState(() {
          loading = true;
        });
        uploadImage();
      }
    });
    // if (pickedFile != null) {
    //   imageFile = File(pickedFile.path);
    //   if (imageFile != null) {
    //     print("12345566566656");
    //     uploadFile();
    //   }
    // }
  }

  // Audio Files Start Here All Code Related to sending Audio

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      recordFilePath = await getFilePath();
      RecordMp3.instance.start(recordFilePath, (type) {
        //setState(() {});
      });
    } else {}
    //setState(() {});
  }

  void stopRecord() async {
    bool stop = RecordMp3.instance.stop();
    audioController.end.value = DateTime.now();
    audioController.calcDuration();
    var ap = AudioPlayer();
    await ap.play(AssetSource("Notification.mp3"));
    ap.onPlayerComplete.listen((a) {});
    if (stop) {
      audioController.isRecording.value = false;
      audioController.isSending.value = true;
      await uploadAudio();
    }
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath =
        "${storageDirectory.path}/record${DateTime.now().microsecondsSinceEpoch}.acc";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return "$sdPath/test_${i++}.mp3";
  }

// uploadVoice() async {
//   connectionService.checkConnection().then((internet) async {
//     if (!internet) {
//       CustomToast.failToast(message: "Not Connected to internet");
//     } else {
//       String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//       final ref = FirebaseStorage.instance
//           .ref()
//           .child('images')
//           .child('$fileName.jgp');
//       var upload = await ref.putFile(recordFilePath!);
//
//        audioURL = await upload.ref.getDownloadURL();
//       //  imageUrl==""?CircularProgressIndicator():SizedBox();
//       print(audioURL);
//
//
//       sendButton(mesContent: audioURL, type: MessageType.audio,duration: audioController.total);
//     }
//   });
// }
  uploadAudio() async {
    UploadTask uploadTask = Get.find<ChatController>().uploadAudio(
        File(recordFilePath),
        "audio/${DateTime.now().millisecondsSinceEpoch.toString()}");
    try {
      TaskSnapshot snapshot = await uploadTask;
      audioURL = await snapshot.ref.getDownloadURL();
      String strVal = audioURL.toString();
      audioController.isSending.value = false;
      Get.log("Total Duration is ${audioController.total}");
      sendButton(
          type: MessageType.audio,
          duration: audioController.total,
          mesContent: strVal);
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(GetStorage().read(auth.currentUser!.uid.toString()))
          .collection("myUsers")
          .get()
          .then((value) {
        if (value.docs.contains(widget.userMap['id'])) {
          print("user is  available");
        } else {
          FirebaseFirestore.instance
              .collection('Users')
              .doc(GetStorage().read(auth.currentUser!.uid.toString()))
              .collection("myUsers")
              .doc(widget.userMap['id'])
              .set(
                  //     {
                  //   'email': widget.groupId,
                  //   'senderId': GetStorage().read(auth.currentUser!.uid.toString()),
                  //   'receiverId': widget.userMap['id'],
                  //   'firstName': widget.userMap['firstName'],
                  //   'lastName': widget.userMap['lastName'],
                  // }
                  widget.userMap);
        }
      });
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userMap['id'])
          .collection("myUsers")
          .get()
          .then((value) {
        if (value.docs
            .contains(GetStorage().read(auth.currentUser!.uid.toString()))) {
          print("user is  available");
        } else {
          //for (var element in value.docs) {
          FirebaseFirestore.instance
              .collection('Users')
              .doc(widget.userMap['id'])
              .collection("myUsers")
              .doc(GetStorage().read(auth.currentUser!.uid.toString()))
              .set({
            'email': auth.currentUser!.email,
            'id': auth.currentUser!.uid,
            'status': "offline",
            'password': "1234445",
            'firstName': GetStorage()
                .read('FirstName${auth.currentUser!.uid.toString()}'),
            'lastName': GetStorage()
                .read('LastName${auth.currentUser!.uid.toString()}'),
            // 'lastName': userDetails.lastName.toString(),
          });
          // }
        }
      });
      // await FirebaseFirestore.instance
      //     .collection("Users")
      //     .doc(Get.find<HomeController>().currentUserID.toString())
      //     .collection("myUsers")
      //     .get()
      //     .then((value) {
      //   if (value.docs.contains(widget.userMap['receiverID'])) {
      //     print("user is  available");
      //   } else {
      //     FirebaseFirestore.instance
      //         .collection('Users')
      //         .doc(Get.find<HomeController>().currentUserID.toString())
      //         .collection("myUsers").doc(widget.userMap['receiverID'])
      //         .set({
      //       'groupId': widget.userMap['groupId'],
      //       'senderId': Get.find<HomeController>().currentUserID.toString(),
      //       'receiverId': widget.userMap['receiverID'],
      //       'firstName': widget.userMap['firstName'],
      //       'lastName': widget.userMap['lastName'],
      //     });
      //   }
      // });
      // await FirebaseFirestore.instance
      //     .collection("Users")
      //     .doc(Get.find<HomeController>().currentUserID.toString())
      //     .collection("myUsers")
      //     .get().then((value) {
      //   if (value.docs.contains(Get.find<HomeController>().currentUserID.toString())) {
      //     print("user is  available");
      //   }
      //   else{
      //     //for (var element in value.docs) {
      //     FirebaseFirestore.instance
      //         .collection('Users')
      //         .doc(widget.userMap['receiverID'])
      //         .collection("myUsers").doc(Get.find<HomeController>().currentUserID.toString())
      //         .set({
      //       'groupId': widget.userMap['groupId'],
      //       'senderId': widget.userMap['receiverID'],
      //       'receiverId': Get.find<HomeController>().currentUserID.toString(),
      //       //'firstName':userDetails.firstName.toString(),
      //       'firstName': Get.find<HomeController>().loggedInUserFirstName.toString(),
      //       'lastName':Get.find<HomeController>().loggedInUserLastName.toString(),
      //       // 'lastName': userDetails.lastName.toString(),
      //     });
      //     // }
      //   }
      // });
    } on FirebaseException catch (e) {
      setState(() {
        audioController.isSending.value = false;
      });
      CustomToast.failToast(message: e.message ?? e.toString());
    }
  }

  Widget audio({
    required String message,
    required bool isCurrentUser,
    required int index,
    required String time,
    required String duration,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: getWidth(200),
        height: getHeight(50),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCurrentUser ? MyColors.primaryColor : MyColors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                audioController.onPressedPlayButton(index, message);
              },
              onSecondaryTap: () {
                audioPlayer.stop();
              },
              child: Obx(
                () => (audioController.isRecordPlaying &&
                        audioController.currentId == index)
                    ? Icon(
                        Icons.cancel,
                        color: isCurrentUser
                            ? Colors.white
                            : MyColors.primaryColor,
                      )
                    : Icon(
                        Icons.play_arrow,
                        color: isCurrentUser
                            ? Colors.white
                            : MyColors.primaryColor,
                      ),
              ),
            ),
            Obx(
              () => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Text(audioController.completedPercentage.value.toString(),style: TextStyle(color: Colors.white),),
                      LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCurrentUser ? Colors.white : MyColors.primaryColor,
                        ),
                        value: (audioController.isRecordPlaying &&
                                audioController.currentId == index)
                            ? audioController.completedPercentage.value
                            : audioController.totalDuration.value.toDouble(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              duration,
              style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser ? Colors.white : MyColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget chatBottomField() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
          color: Colors.white),
      child: Row(
        children: <Widget>[
          // Button send image
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
                onTap: () {
                  showGeneralDialog(
                    //barrierLabel: "Label",
                    //barrierDismissible: true,
                    barrierColor: Colors.black.withOpacity(0.5),
                    transitionDuration: const Duration(milliseconds: 700),
                    context: context,
                    pageBuilder: (context, anim1, anim2) {
                      return Material(
                        type: MaterialType.transparency,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: getHeight(250),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: MyColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            Text(
                                              "Documents",
                                              style: TextStyle(
                                                  fontSize: getFont(14)),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            GestureDetector(
                                               onTap:(){
                                                 loading ? const CircularProgressIndicator() : getImageCamera();
                                                 Get.back();
                                               },
                                              child: Container(
                                                height: getHeight(60),
                                                width: getWidth(70),
                                                decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle),
                                                child: Icon(
                                                  Icons.photo_camera,
                                                  size: getHeight(30),
                                                  color: MyColors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: getHeight(5),
                                            ),
                                            Text(
                                              "Photo",
                                              style: TextStyle(
                                                  fontSize: getFont(14)),
                                            )
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                loading ? const CircularProgressIndicator() : getImageGallery();
                                                Get.back();
                                              },
                                              child: Container(
                                                height: getHeight(60),
                                                width: getWidth(70),
                                                decoration: const BoxDecoration(
                                                    color:
                                                        Colors.deepPurpleAccent,
                                                    shape: BoxShape.circle),
                                                child: Icon(
                                                  Icons.collections_bookmark,
                                                  size: getHeight(30),
                                                  color: MyColors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: getHeight(5),
                                            ),
                                            Text(
                                              "Gallery",
                                              style: TextStyle(
                                                  fontSize: getFont(14)),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: getHeight(20),),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              height: getHeight(60),
                                              width: getWidth(70),
                                              decoration: const BoxDecoration(
                                                  color:
                                                      Colors.deepOrangeAccent,
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
                                            Text(
                                              "Audio",
                                              style: TextStyle(
                                                  fontSize: getFont(14)),
                                            )
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
                                            Text(
                                              "Location",
                                              style: TextStyle(
                                                  fontSize: getFont(14)),
                                            )
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
                                            Text(
                                              "Contact",
                                              style: TextStyle(
                                                  fontSize: getFont(14)),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    // transitionBuilder: (context, anim1, anim2, child) {
                    //   return SlideTransition(
                    //     position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(anim1),
                    //     child: child,
                    //   );
                    // },
                  );
                  //dialogueBox();
                  //loading ? const CircularProgressIndicator() : getImageGallery();
                },
                child: const Icon(
                  Icons.attach_file,
                  color: MyColors.primaryColor,
                )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
                onLongPress: () async {
                  //Get.log("123456789077445423");
                  var audioPlayer = AudioPlayer();
                  await audioPlayer.play(AssetSource("Notification.mp3"));
                  audioPlayer.onPlayerComplete.listen((a) {
                    audioController.start.value = DateTime.now();
                    //Get.log("123456789077445423${audioController.start.value}");
                    startRecord();
                    audioController.isRecording.value = true;
                  });
                },
                onLongPressEnd: (details) {
                  stopRecord();
                },
                child: const Icon(
                  Icons.mic,
                  color: MyColors.primaryColor,
                )),
          ),
          // Material(
          //   child: Container(
          //     margin: EdgeInsets.symmetric(horizontal: 1),
          //     child: IconButton(
          //       icon: Icon(Icons.image),
          //       //onPressed: getImage,
          //       color: MyColors.primaryColor,
          //       onPressed: () {  },
          //     ),
          //   ),
          //   color: Colors.white,
          // ),
          // Material(
          //   child: Container(
          //     margin: EdgeInsets.symmetric(horizontal: 1),
          //     child: IconButton(
          //       icon: Icon(Icons.face),
          //       onPressed: getSticker,
          //       color: ColorConstants.primaryColor,
          //     ),
          //   ),
          //   color: Colors.white,
          // ),

          // Edit text
          Flexible(
            child: TextField(
              maxLines: null,
              maxLength: null,
              keyboardType: TextInputType.streetAddress,
              onSubmitted: (value) {
                //onSendMessage(textEditingController.text, TypeMessage.text);
              },
              style: const TextStyle(color: MyColors.black, fontSize: 15),
              controller: Get.find<ChatController>().chatFieldController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              //focusNode: focusNode,
              autofocus: true,
            ),
          ),
          // Button send message
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  //Get.log("sender id is   ${GetStorage().read(auth.currentUser!.uid.toString())}");
                  //Get.log("Receiver id is   ${widget.userMap['id']}");
                  //Get.log("Receiver id is   ${widget.userMap['firstName']}");
                  //Get.log("Receiver id is   ${widget.userMap['lastName']}");
                  //Get.log("Receiver id is   ${widget.userMap['id']}");
                  sendButton(
                      type: MessageType.text,
                      mesContent: Get.find<ChatController>()
                          .chatFieldController
                          .text
                          .toString());
                  await FirebaseFirestore.instance
                      .collection("Users")
                      .doc(GetStorage().read(auth.currentUser!.uid.toString()))
                      .collection("myUsers")
                      .get()
                      .then((value) {
                    if (value.docs.contains(widget.userMap['id'])) {
                      print("user is  available");
                    } else {
                      FirebaseFirestore.instance
                          .collection('Users')
                          .doc(GetStorage()
                              .read(auth.currentUser!.uid.toString()))
                          .collection("myUsers")
                          .doc(widget.userMap['id'])
                          .set(
                              //     {
                              //   'email': widget.groupId,
                              //   'senderId': GetStorage().read(auth.currentUser!.uid.toString()),
                              //   'receiverId': widget.userMap['id'],
                              //   'firstName': widget.userMap['firstName'],
                              //   'lastName': widget.userMap['lastName'],
                              // }
                              widget.userMap);
                    }
                  });
                  await FirebaseFirestore.instance
                      .collection("Users")
                      .doc(widget.userMap['id'])
                      .collection("myUsers")
                      .get()
                      .then((value) {
                    if (value.docs.contains(
                        GetStorage().read(auth.currentUser!.uid.toString()))) {
                      print("user is  available");
                    } else {
                      //for (var element in value.docs) {
                      FirebaseFirestore.instance
                          .collection('Users')
                          .doc(widget.userMap['id'])
                          .collection("myUsers")
                          .doc(GetStorage()
                              .read(auth.currentUser!.uid.toString()))
                          .set({
                        'email': auth.currentUser!.email,
                        'id': auth.currentUser!.uid,
                        'status': "offline",
                        'password': "1234445",
                        'firstName': GetStorage().read(
                            'FirstName${auth.currentUser!.uid.toString()}'),
                        'lastName': GetStorage().read(
                            'LastName${auth.currentUser!.uid.toString()}'),
                        // 'lastName': userDetails.lastName.toString(),
                      });
                      // }
                    }
                  });
                },
                // onPressed: () {
                //   Get.log("TextEditing value is ${Get.find<ChatController>().chatFieldController.text.toString()}");
                //   String id = (sendToUserID.hashCode +
                //           Get.find<HomeController>().currentUserID.hashCode)
                //       .toString();
                //   print("Combine id is $id ");
                //   if (Get.find<ChatController>()
                //       .chatFieldController
                //       .text
                //       .isNotEmpty) {
                //     Get.find<ChatController>().sendMessage(
                //         groupID: id,
                //         messageContent: Get.find<ChatController>()
                //             .chatFieldController
                //             .text
                //             .toString(),
                //         receiverId: sendToUserID,
                //         senderId: Get.find<HomeController>()
                //             .currentUserID
                //             .toString());
                //     Get.find<ChatController>()
                //         .chatFieldController.clear();
                //   } else {
                //     CustomToast.failToast(
                //         message: "Nothing to Send Pleast Type Message");
                //   }
                //   //  onSendMessage(textEditingController.text, TypeMessage.text)
                // },
                color: MyColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: widget.groupId.isNotEmpty
          ? StreamBuilder(
              stream: Get.find<ChatController>().getAllMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  Get.find<ChatController>().messagesList =
                      snapshot.data!.docs.reversed.toList();
                  if (Get.find<ChatController>().messagesList.isNotEmpty) {
                    Get.log(
                        "Last Message is ${Get.find<ChatController>().messagesList.last}");
                    // return Container(
                    //     margin: const EdgeInsets.only(bottom: 10),
                    //     child: ListView(
                    //       reverse: true,
                    //       children: [Column(
                    //           //crossAxisAlignment: CrossAxisAlignment.start,
                    //           mainAxisAlignment: MainAxisAlignment.end,
                    //           children: snapshot.data!.docs
                    //               .map((doc) => GestureDetector(
                    //             // onTap: () async {
                    //             //   //String id=(sendToUserID.hashCode+ Get.find<HomeController>().currentUserID.hashCode).toString();
                    //             //   await Get.find<HomeController>()
                    //             //       .getCurrentUserID();
                    //             //   Get.to(ChatScreen(
                    //             //     firstName: doc["firstName"],
                    //             //     lastName: doc['lastName'],
                    //             //     currentUserID:(Get.find<HomeController>().currentUserID).toString() ,
                    //             //     sendToUserID: doc.id,
                    //             //     groupId: (doc.id.hashCode +
                    //             //         Get.find<HomeController>()
                    //             //             .currentUserID
                    //             //             .hashCode)
                    //             //         .toString(),
                    //             //   ));
                    //             //   print('document id  ${doc.id}');
                    //             //   print(
                    //             //       'groupId  ${(doc.id.hashCode + Get.find<HomeController>().currentUserID.hashCode)}');
                    //             //   print(
                    //             //       'current user id  ${Get.find<HomeController>().currentUserID}');
                    //             //   //print('current user id  ${Get.find<HomeController>().currentUserID}');
                    //             // },
                    //             child: Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: currentUserID ==
                    //                   doc['sender']
                    //                   ? Align(
                    //                 alignment:
                    //                 Alignment.bottomRight,
                    //                 child: Container(
                    //                   //alignment: Alignment.bottomRight,
                    //                     width: getWidth(100),
                    //                     decoration:
                    //                     const BoxDecoration(
                    //                       color: MyColors
                    //                           .primaryColor,
                    //                     ),
                    //                     child: Text(
                    //                       "${doc["message"]}",
                    //                       style:
                    //                       const TextStyle(
                    //                           color: Colors
                    //                               .white),
                    //                     )),
                    //               )
                    //                   : Align(
                    //                 alignment:
                    //                 Alignment.bottomLeft,
                    //                 child: Container(
                    //                     alignment: Alignment
                    //                         .bottomLeft,
                    //                     width: getWidth(100),
                    //                     decoration:
                    //                     const BoxDecoration(
                    //                       color: MyColors
                    //                           .primaryColor,
                    //                     ),
                    //                     child: Text(
                    //                       "${doc["message"]}",
                    //                       style:
                    //                       const TextStyle(
                    //                           color: Colors
                    //                               .black),
                    //                     )),
                    //               ),
                    //             ),
                    //           )).toList()
                    //       ),
                    //   ]
                    //     ),
                    //   );
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(10),
                      itemBuilder: (context, index) => buildItem(index,
                          Get.find<ChatController>().messagesList[index]),
                      itemCount: Get.find<ChatController>().messagesList.length,
                      //controller: listScrollController,
                    );
                    // return ListView.builder(
                    //   padding: const EdgeInsets.all(10),
                    //   //itemBuilder: (context, index) => buildItem(index, snapshot.data?.docs[index]),
                    //   itemBuilder: (context, index) =>
                    //   sendToUserID != currentUserID? Row(
                    //     children: [
                    //       Container(
                    //         padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    //         width: 200,
                    //         child: Text(Get.find<ChatController>().chatFieldController.text.toString(),
                    //           style: const TextStyle(color: MyColors.primaryColor),
                    //         ),
                    //         //decoration: BoxDecoration(color: MyColors.greyColor2, borderRadius: BorderRadius.circular(8)),
                    //         //margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
                    //       )
                    //     ],
                    //   ):Container(color: Colors.red,height: 200,),
                    //   itemCount: snapshot.data?.docs.length,
                    //   reverse: true,
                    //   //controller: listScrollController,
                    // );
                  } else {
                    return const Center(child: Text("No message here yet..."));
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: MyColors.primaryColor,
                    ),
                  );
                }
              })
          : const Center(
              child: CircularProgressIndicator(
                color: MyColors.primaryColor,
              ),
            ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    MessageModel messageModel = MessageModel.fromJson(document!);
    //Get.log("current id from model is ${messageModel.currentID}  $index");
    //Get.log("current id from model is ${GetStorage().read(auth.currentUser!.uid.toString())}  $index");
    if (messageModel.currentID ==
        GetStorage().read(auth.currentUser!.uid.toString())) {
      // Right (my message)
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (messageModel.type == MessageType.text)
            Align(
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            //Get.find<ChatController>().deleteSingleMessage(groupId: widget.groupId, messageId: messageModel.messageId);
                            Get.log("Text Message is Pressed$index");
                          },
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth: getWidth(200),
                                minHeight: getHeight(45),
                                minWidth: getWidth(100)),
                            //width: getWidth(200),
                            decoration: BoxDecoration(
                                color: MyColors.primaryColor,
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                messageModel.messageContent,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: getHeight(10),
                        right: getWidth(10),
                        child: Row(
                          children: [
                            Text(
                              DateFormatUtil.getFormattedTime(
                                  context: context,
                                  time: messageModel.timestamp),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: MyColors.white.withOpacity(0.8)),
                            ),
                            StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(widget.userMap['id'])
                                  .snapshots(),
                              builder: (context, snapshot1) {
                                return StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection('chat')
                                      .doc(widget.groupId)
                                      .collection(widget.groupId)
                                      .doc(messageModel.messageId)
                                      .snapshots(),
                                  builder: (context, snapshot2) {
                                    if (snapshot1.connectionState ==
                                            ConnectionState.waiting ||
                                        snapshot2.connectionState ==
                                            ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: MyColors.primaryColor,
                                        ),
                                      );
                                    } else {
                                      if (snapshot1.connectionState ==
                                              ConnectionState.active ||
                                          snapshot1.connectionState ==
                                              ConnectionState.done ||
                                          snapshot2.connectionState ==
                                              ConnectionState.active ||
                                          snapshot2.connectionState ==
                                              ConnectionState.done) {
                                        if (snapshot1.hasError ||
                                            snapshot2.hasError) {
                                          return Text(
                                              snapshot1.error.toString());
                                        } else {
                                          return snapshot1.data!['status'] ==
                                                      'Online' &&
                                                  snapshot2.data![
                                                          'readStatus'] ==
                                                      false
                                              ? Icon(Icons.done_all,
                                                  color: MyColors.black,
                                                  size: getHeight(15))
                                              : snapshot2.data!['readStatus'] ==
                                                      true
                                                  ? Icon(Icons.done_all,
                                                      color: MyColors.blue10,
                                                      size: getHeight(15))
                                                  : Icon(Icons.check,
                                                      size: getHeight(15));
                                        }
                                      }
                                    }
                                    return const SizedBox();

                                    // do some stuff with both streams here
                                  },
                                );
                              },
                            ),
                            // StreamBuilder(
                            //     stream: FirebaseFirestore.instance
                            //         .doc(messageModel.messageId).snapshots(),
                            //     builder: (context, snapshot) {
                            //       if(snapshot.connectionState==ConnectionState.waiting){
                            //         return const Center(child: CircularProgressIndicator(color: MyColors.primaryColor,),);
                            //       }
                            //       if(snapshot.connectionState == ConnectionState.done || snapshot.connectionState == ConnectionState.active){
                            //         if(snapshot.hasError){
                            //           return const SizedBox();
                            //         }
                            //         else {
                            //           return snapshot.data!['status'] == 'Online'
                            //               ? Icon(
                            //               Icons.done_all, size: getHeight(15))
                            //               : Icon(
                            //               Icons.check, size: getHeight(15));
                            //         }
                            //       }
                            //       return const SizedBox();
                            //       },
                            // )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            messageModel.type == MessageType.image
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                      maxWidth: getWidth(200),
                                      minHeight: getHeight(200),
                                      maxHeight: getHeight(200),
                                      minWidth: getWidth(200)),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8)),
                                  //height: getHeight(200),
                                  //width: getWidth(200),
                                  //decoration: BoxDecoration(color: Colors.red),
                                  child: messageModel.messageContent != ""
                                      ? Image.network(
                                          messageModel.messageContent
                                              .toString(),
                                          fit: BoxFit.cover,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent?
                                                  loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              decoration: const BoxDecoration(
                                                color: MyColors.transparent,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                              ),
                                              width: getWidth(200),
                                              height: getHeight(200),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: MyColors.primaryColor,
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : const CircularProgressIndicator(
                                          color: MyColors.primaryColor,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: getHeight(10),
                            right: getWidth(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    DateFormatUtil.getFormattedTime(
                                        context: context,
                                        time: messageModel.timestamp),
                                    // ' ${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).hour.toString())}:'
                                    // '${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).minute.toString())}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: MyColors.white.withOpacity(0.8)),
                                  ),
                                  StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection('Users')
                                        .doc(widget.userMap['id'])
                                        .snapshots(),
                                    builder: (context, snapshot1) {
                                      return StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection('chat')
                                            .doc(widget.groupId)
                                            .collection(widget.groupId)
                                            .doc(messageModel.messageId)
                                            .snapshots(),
                                        builder: (context, snapshot2) {
                                          if (snapshot1.connectionState ==
                                                  ConnectionState.waiting ||
                                              snapshot2.connectionState ==
                                                  ConnectionState.waiting) {
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                color: MyColors.primaryColor,
                                              ),
                                            );
                                          } else {
                                            if (snapshot1.connectionState ==
                                                    ConnectionState.active ||
                                                snapshot1.connectionState ==
                                                    ConnectionState.done ||
                                                snapshot2.connectionState ==
                                                    ConnectionState.active ||
                                                snapshot2.connectionState ==
                                                    ConnectionState.done) {
                                              if (snapshot1.hasError ||
                                                  snapshot2.hasError) {
                                                return Text(
                                                    snapshot1.error.toString());
                                              } else {
                                                return snapshot1.data![
                                                                'status'] ==
                                                            'Online' &&
                                                        snapshot2.data![
                                                                'readStatus'] ==
                                                            false
                                                    ? Icon(Icons.done_all,
                                                        color: MyColors.black,
                                                        size: getHeight(15))
                                                    : snapshot2.data![
                                                                'readStatus'] ==
                                                            true
                                                        ? Icon(
                                                            Icons.done_all,
                                                            color:
                                                                MyColors.blue10,
                                                            size: getHeight(15))
                                                        : Icon(Icons.check,
                                                            size:
                                                                getHeight(15));
                                              }
                                            }
                                          }
                                          return const SizedBox();

                                          // do some stuff with both streams here
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      //:SizedBox(height: getHeight(200),width: getWidth(200),
                      //child: const Center(child: CircularProgressIndicator(color: MyColors.primaryColor,),),),
                    ],
                  )
                : messageModel.type == MessageType.audio
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Stack(
                            children: [
                              audio(
                                  message: messageModel.messageContent,
                                  isCurrentUser: messageModel.currentID ==
                                      Get.find<HomeController>().currentUserID,
                                  index: index,
                                  time: messageModel.timestamp.toString(),
                                  duration: messageModel.duration.toString()),
                              SizedBox(
                                height: getHeight(3),
                              ),
                              Positioned(
                                bottom: getHeight(10),
                                right: getWidth(10),
                                child: Row(
                                  children: [
                                    Text(
                                      DateFormatUtil.getFormattedTime(
                                          context: context,
                                          time: messageModel.timestamp),
                                      // ' ${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).hour.toString())}:'
                                      // '${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).minute.toString())}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              MyColors.white.withOpacity(0.8)),
                                    ),
                                    StreamBuilder(
                                      stream: FirebaseFirestore.instance
                                          .collection('Users')
                                          .doc(widget.userMap['id'])
                                          .snapshots(),
                                      builder: (context, snapshot1) {
                                        return StreamBuilder(
                                          stream: FirebaseFirestore.instance
                                              .collection('chat')
                                              .doc(widget.groupId)
                                              .collection(widget.groupId)
                                              .doc(messageModel.messageId)
                                              .snapshots(),
                                          builder: (context, snapshot2) {
                                            if (snapshot1.connectionState ==
                                                    ConnectionState.waiting ||
                                                snapshot2.connectionState ==
                                                    ConnectionState.waiting) {
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: MyColors.primaryColor,
                                                ),
                                              );
                                            } else {
                                              if (snapshot1.connectionState ==
                                                      ConnectionState.active ||
                                                  snapshot1.connectionState ==
                                                      ConnectionState.done ||
                                                  snapshot2.connectionState ==
                                                      ConnectionState.active ||
                                                  snapshot2.connectionState ==
                                                      ConnectionState.done) {
                                                if (snapshot1.hasError ||
                                                    snapshot2.hasError) {
                                                  return Text(snapshot1.error
                                                      .toString());
                                                } else {
                                                  return snapshot1.data![
                                                                  'status'] ==
                                                              'Online' &&
                                                          snapshot2.data![
                                                                  'readStatus'] ==
                                                              false
                                                      ? Icon(Icons.done_all,
                                                          color: MyColors.black,
                                                          size: getHeight(15))
                                                      : snapshot2.data![
                                                                  'readStatus'] ==
                                                              true
                                                          ? Icon(
                                                              Icons.done_all,
                                                              color: MyColors
                                                                  .blue10,
                                                              size:
                                                                  getHeight(15))
                                                          : Icon(Icons.check,
                                                              size: getHeight(
                                                                  15));
                                                }
                                              }
                                            }
                                            return const SizedBox();

                                            // do some stuff with both streams here
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(
                        color: MyColors.primaryColor,
                      )
        ],
      );
      // return Row(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: <Widget>[
      //     Container(
      //       padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      //       width: 200,
      //       decoration: BoxDecoration(
      //           color: Colors.grey, borderRadius: BorderRadius.circular(8)),
      //       //margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
      //       child: Text(
      //         messageModel.messageContent,
      //         style: const TextStyle(color: MyColors.primaryColor),
      //       ),
      //     )
      //     //     : messageChat.type == TypeMessage.image
      //     // // Image
      //     //     ? Container(
      //     //   child: OutlinedButton(
      //     //     child: Material(
      //     //       child: Image.network(
      //     //         messageChat.content,
      //     //         loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
      //     //           if (loadingProgress == null) return child;
      //     //           return Container(
      //     //             decoration: BoxDecoration(
      //     //               color: ColorConstants.greyColor2,
      //     //               borderRadius: BorderRadius.all(
      //     //                 Radius.circular(8),
      //     //               ),
      //     //             ),
      //     //             width: 200,
      //     //             height: 200,
      //     //             child: Center(
      //     //               child: CircularProgressIndicator(
      //     //                 color: ColorConstants.themeColor,
      //     //                 value: loadingProgress.expectedTotalBytes != null
      //     //                     ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
      //     //                     : null,
      //     //               ),
      //     //             ),
      //     //           );
      //     //         },
      //     //         errorBuilder: (context, object, stackTrace) {
      //     //           return Material(
      //     //             child: Image.asset(
      //     //               'images/img_not_available.jpeg',
      //     //               width: 200,
      //     //               height: 200,
      //     //               fit: BoxFit.cover,
      //     //             ),
      //     //             borderRadius: BorderRadius.all(
      //     //               Radius.circular(8),
      //     //             ),
      //     //             clipBehavior: Clip.hardEdge,
      //     //           );
      //     //         },
      //     //         width: 200,
      //     //         height: 200,
      //     //         fit: BoxFit.cover,
      //     //       ),
      //     //       borderRadius: BorderRadius.all(Radius.circular(8)),
      //     //       clipBehavior: Clip.hardEdge,
      //     //     ),
      //     //     onPressed: () {
      //     //       Navigator.push(
      //     //         context,
      //     //         MaterialPageRoute(
      //     //           builder: (context) => FullPhotoPage(
      //     //             url: messageChat.content,
      //     //           ),
      //     //         ),
      //     //       );
      //     //     },
      //     //     style: ButtonStyle(padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(0))),
      //     //   ),
      //     //   margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
      //     // )
      //     // // Sticker
      //     //     : Container(
      //     //   child: Image.asset(
      //     //     'images/${messageChat.content}.gif',
      //     //     width: 100,
      //     //     height: 100,
      //     //     fit: BoxFit.cover,
      //     //   ),
      //     //   margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
      //     // ),
      //   ],
      // );
      // } else {
      //   // Left (peer message)
      //   return Column(
      //     children: <Widget>[
      //       Container(
      //         padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      //         width: 200,
      //         decoration: BoxDecoration(
      //             color: MyColors.primaryColor,
      //             borderRadius: BorderRadius.circular(8)),
      //         margin: const EdgeInsets.only(left: 10),
      //         child: Text(
      //           messageModel.messageContent,
      //           style: const TextStyle(color: Colors.white),
      //         ),
      //       )
      //     ],
      //   );
      // }
    } else {
      if (messageModel.readStatus == false) {
        Get.find<ChatController>()
            .updateMessageReadStatus(messageModel, widget.groupId);
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          messageModel.type == MessageType.text
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth: getWidth(200),
                                  minHeight: getHeight(40),
                                  minWidth: getWidth(80)),
                              //width: getWidth(200),
                              decoration: BoxDecoration(
                                  color: MyColors.black,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  messageModel.messageContent,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: getHeight(10),
                            right: getWidth(10),
                            child: Row(
                              children: [
                                Text(
                                  DateFormatUtil.getFormattedTime(
                                      context: context,
                                      time: messageModel.timestamp!),
                                  // ' ${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).hour.toString())}:'
                                  // '${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).minute.toString())}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: MyColors.white.withOpacity(0.8)),
                                ),
                                // StreamBuilder(
                                //   stream: FirebaseFirestore.instance
                                //       .collection('Users')
                                //       .doc(widget.sendToUserID)
                                //       .snapshots(),
                                //   builder: (context, snapshot1) {
                                //     return StreamBuilder(
                                //       stream: FirebaseFirestore.instance
                                //           .collection('chat')
                                //           .doc(widget.groupId)
                                //           .collection(widget.groupId)
                                //           .doc(messageModel.messageId)
                                //           .snapshots(),
                                //       builder: (context, snapshot2) {
                                //         if (snapshot1.connectionState ==
                                //             ConnectionState.waiting ||
                                //             snapshot2.connectionState ==
                                //                 ConnectionState.waiting) {
                                //           return const Center(
                                //             child: CircularProgressIndicator(
                                //               color: MyColors.primaryColor,
                                //             ),
                                //           );
                                //         } else {
                                //           if (snapshot1.connectionState ==
                                //               ConnectionState.active ||
                                //               snapshot1.connectionState ==
                                //                   ConnectionState.done ||
                                //               snapshot2.connectionState ==
                                //                   ConnectionState.active ||
                                //               snapshot2.connectionState ==
                                //                   ConnectionState.done) {
                                //             if(snapshot1.hasError || snapshot2.hasError){
                                //               return Text(snapshot1.error.toString());
                                //             }
                                //             else{
                                //               return snapshot1.data!['status'] ==
                                //                   'Online' &&
                                //                   snapshot2.data!['readStatus'] ==
                                //                       false
                                //                   ? Icon(Icons.done_all,
                                //                   color: MyColors.black,
                                //                   size: getHeight(15))
                                //                   : snapshot2.data!['readStatus'] == true
                                //                   ? Icon(Icons.done_all,
                                //                   color: MyColors.blue10,
                                //                   size: getHeight(15))
                                //                   : Icon(Icons.check,
                                //                   size: getHeight(15));
                                //             }
                                //           }
                                //         }
                                //         return const SizedBox();
                                //
                                //         // do some stuff with both streams here
                                //       },
                                //     );
                                //   },
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : messageModel.type == MessageType.image
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: getWidth(200),
                                    minHeight: getHeight(200),
                                    maxHeight: getHeight(200),
                                    minWidth: getWidth(200)),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8)),
                                //height: getHeight(200),
                                //width: getWidth(200),
                                //decoration: BoxDecoration(color: Colors.red),
                                child: Image.network(
                                  messageModel.messageContent.toString(),
                                  fit: BoxFit.cover,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      decoration: const BoxDecoration(
                                        color: MyColors.transparent,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                      width: getWidth(200),
                                      height: getHeight(200),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: MyColors.primaryColor,
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: getHeight(10),
                              right: getWidth(10),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.8)),
                                child: Row(
                                  children: [
                                    Text(
                                      DateFormatUtil.getFormattedTime(
                                          context: context,
                                          time: messageModel.timestamp!),
                                      // ' ${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).hour.toString())}:'
                                      // '${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).minute.toString())}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              MyColors.white.withOpacity(0.8)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                        //:SizedBox(height: getHeight(200),width: getWidth(200),
                        //child: const Center(child: CircularProgressIndicator(color: MyColors.primaryColor,),),),
                      ],
                    )
                  : messageModel.type == MessageType.audio
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Stack(
                              children: [
                                audio(
                                    message: messageModel.messageContent,
                                    isCurrentUser: messageModel.currentID ==
                                        Get.find<HomeController>()
                                            .currentUserID,
                                    index: index,
                                    time: messageModel.timestamp.toString(),
                                    duration: messageModel.duration.toString()),
                                SizedBox(
                                  height: getHeight(3),
                                ),
                                Positioned(
                                  bottom: getHeight(10),
                                  right: getWidth(10),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormatUtil.getFormattedTime(
                                            context: context,
                                            time: messageModel.timestamp!),
                                        // ' ${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).hour.toString())}:'
                                        // '${(DateTime.fromMillisecondsSinceEpoch(int.parse(messageModel.timestamp)).minute.toString())}',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: MyColors.white
                                                .withOpacity(0.8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const CircularProgressIndicator(
                          color: MyColors.primaryColor,
                        )
        ],
      );
    }
  }

  Future<bool> dialogueBox() async {
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
