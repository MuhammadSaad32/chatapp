import 'package:chat_app/controllers/homeController/home_controller.dart';
import 'package:chat_app/ui/screens/video/video_play_screen.dart';
import 'package:chat_app/ui/screens/home/home_screen.dart';
import 'package:chat_app/ui/widgets/dialogue_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/controllers/chatController/chat_controller.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

import '../contacts/contact_list_screen.dart';

class ChatScreen extends StatefulWidget {
  dynamic userMap;
  String groupId;
  ChatScreen({
    super.key,
    this.userMap,
    required this.groupId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  File? imageFile;
  File? videoFile;
  double? lat;
  MessageModel? message;
  double? log;
  List<String> myLocation = [];
  File? audioFile;
  FirebaseAuth auth = FirebaseAuth.instance;
  AudioController audioController = Get.put(AudioController());
  bool loading = false;
  AudioPlayer audioPlayer = AudioPlayer();
  CheckConnectionService connectionService = CheckConnectionService();
  String audioURL = "";
  String recordFilePath = "";
  String imageUrl = "";
  String videoUrl = "";
  Position? currentPosition;
  final ScrollController _scrollController = ScrollController();
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void navigateTo({required double lat, required double lng}) async {
    // void launchMapsUrl(String plat, String plng, String dlat, String dlng) async {
    String mapOptions = [
      //'saddr=$lat,$lng',
      'daddr=$lat,$lng',
      'dir_action=navigate'
    ].join('&');

    final url = 'https://www.google.com/maps?$mapOptions';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
    //}
// var uri = Uri.parse("google.navigation:q=$lat,$lng");
// if (await canLaunch(uri.toString())) {
// await launch(uri.toString());
// } else {
// throw 'Could not launch ${uri.toString()}';
// }
  }

  void sendButton({
    required String mesContent,
    required int type,
    bool readStatus = false,
    //String? userStatus = "Offline",
    String duration = "",
  }) {
    if (mesContent.trim().isNotEmpty) {
      var uuid = const Uuid();
      //Get.find<ChatController>().chatFieldController.clear();
      Get.find<ChatController>().sendMessage1(
          messageContent: mesContent,
          readStatus: readStatus,
          //userStatus: userStatus!,
          type: type,
          messageId: uuid.v1(),
          receiverFName: widget.userMap["firstName"],
          receiverLName: widget.userMap["lastName"],
          senderId: GetStorage().read(auth.currentUser!.uid.toString()),
          receiverId: widget.userMap['id'],
          groupID: widget.groupId,
          duration: duration,
          timeStamp: DateTime.now().millisecondsSinceEpoch.toString());
      Get.find<ChatController>().sendMessage2(
          messageContent: mesContent,
          readStatus: readStatus,
          //userStatus: userStatus!,
          type: type,
          messageId: uuid.v1(),
          receiverFName: widget.userMap["firstName"],
          receiverLName: widget.userMap["lastName"],
          senderId: GetStorage().read(auth.currentUser!.uid.toString()),
          receiverId: widget.userMap['id'],
          groupID: widget.groupId,
          duration: duration,
          timeStamp: DateTime.now().millisecondsSinceEpoch.toString());

      // if (listScrollController.hasClients) {
      //   listScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      // }
    } else {
      CustomToast.failToast(message: 'Nothing to send');
    }
  }

  @override
  void initState() {
    // _initializeVideoPlayerFuture = _controller!.initialize();
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.hasPixels ==
          _scrollController.position.minScrollExtent) {
        Get.find<ChatController>().getAllMessages(widget.groupId);
      }
    });
  }

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
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                print(value);
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: "Delete Chat",
                    child: const Text("Delete Chat"),
                    onTap: () {
                      Get.log("Chat is Pressed   ${widget.groupId}");
                      Get.log("Chat is Pressed   ${auth.currentUser!.uid}");
                      Get.find<ChatController>()
                          .deleteChat(groupId: widget.groupId);
                    },
                  ),
                  const PopupMenuItem(
                    value: "Settings",
                    child: Text("Settings"),
                  ),
                ];
              },
            ),
            //const Icon(Icons.more_vert)
          ],
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
        // var upload;
        // String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        // loading = true;
        // sendButton(mesContent: '', type: MessageType.image);
        // final ref = FirebaseStorage.instance
        //     .ref()
        //     .child('images')
        //     .child('$fileName.jgp');
        //
        // await ref.putFile(imageFile!).then((p0) {
        //   setState(() {
        //     upload = p0;
        //     loading = false;
        //   });
        // });
        // //imageUrl==""?const CircularProgressIndicator():SizedBox();
        // imageUrl = await upload.ref.getDownloadURL();
        // print(imageUrl);
        String fileName = const Uuid().v1();
        int status = 1;
        await FirebaseFirestore.instance
            .collection('chatRoom')
            .doc(widget.groupId)
            .collection('ChatUsers')
            .doc(auth.currentUser!.uid)
            .collection('message')
            .doc(fileName)
            .set({
          'message': '',
          'sender': auth.currentUser!.uid,
          'receiver': widget.userMap['id'],
          'receiverFName': widget.userMap['firstName'],
          'receiverLName': widget.userMap['lastName'],
          'timeStamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'messageId': fileName,
          'lastMessage': 'Image',
          'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
          'messageType': MessageType.image,
          'readStatus': false,
          //'userStatus': userStatus,
          'duration': ''
        });
        await FirebaseFirestore.instance
            .collection('chatRoom')
            .doc(widget.groupId)
            .collection('ChatUsers')
            .doc(widget.userMap['id'])
            .collection('message')
            .doc(fileName)
            .set({
          'message': '',
          'sender': auth.currentUser!.uid,
          'receiver': widget.userMap['id'],
          'receiverFName': widget.userMap['firstName'],
          'receiverLName': widget.userMap['lastName'],
          'timeStamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'messageId': fileName,

          'messageType': MessageType.image,
          'readStatus': false,
          //'userStatus': userStatus,
          'duration': ''
        });

        var ref = FirebaseStorage.instance
            .ref()
            .child('images')
            .child('$fileName.jpg');

        var uploadTask =
            await ref.putFile(imageFile!).catchError((error) async {
          await FirebaseFirestore.instance
              .collection('chatRoom')
              .doc(widget.groupId)
              .collection('ChatUsers')
              .doc(auth.currentUser!.uid)
              .collection('message')
              .doc(fileName)
              .delete();

          status = 0;
        });
        if (status == 1) {
          imageUrl = await uploadTask.ref.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('chatRoom')
              .doc(widget.groupId)
              .collection('ChatUsers')
              .doc(auth.currentUser!.uid)
              .collection('message')
              .doc(fileName)
              .update({'message': imageUrl});
          await FirebaseFirestore.instance
              .collection('chatRoom')
              .doc(widget.groupId)
              .collection('ChatUsers')
              .doc(widget.userMap['id'])
              .collection('message')
              .doc(fileName)
              .update({'message': imageUrl});
        }

        // sendButton(mesContent: imageUrl, type: MessageType.image,);

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
                .set({
              'email': widget.userMap['email'],
              'id': widget.userMap['id'],
              'status': "offline",
              'lastMessage': 'Image',
              'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
              'password': "1234445",
              'firstName': widget.userMap['firstName'],
              'lastName': widget.userMap['lastName'],
              // 'lastName': userDetails.lastName.toString(),
            });
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
              'lastMessage': 'Image',
              'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
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

  Future uploadVideo() async {
    connectionService.checkConnection().then((internet) async {
      if (!internet) {
        CustomToast.failToast(message: "Not Connected to internet");
      } else {
        // var upload;
        // String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        // loading = true;
        // sendButton(mesContent: '', type: MessageType.image);
        // final ref = FirebaseStorage.instance
        //     .ref()
        //     .child('images')
        //     .child('$fileName.jgp');
        //
        // await ref.putFile(imageFile!).then((p0) {
        //   setState(() {
        //     upload = p0;
        //     loading = false;
        //   });
        // });
        // //imageUrl==""?const CircularProgressIndicator():SizedBox();
        // imageUrl = await upload.ref.getDownloadURL();
        // print(imageUrl);
        String fileName = const Uuid().v1();
        int status = 1;
        await FirebaseFirestore.instance
            .collection('chatRoom')
            .doc(widget.groupId)
            .collection('ChatUsers')
            .doc(auth.currentUser!.uid)
            .collection('message')
            .doc(fileName)
            .set({
          'message': '',
          'sender': auth.currentUser!.uid,
          'receiver': widget.userMap['id'],
          'receiverFName': widget.userMap['firstName'],
          'receiverLName': widget.userMap['lastName'],
          'timeStamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'messageId': fileName,
          'messageType': MessageType.video,
          'readStatus': false,
          //'userStatus': userStatus,
          'duration': ''
        });
        await FirebaseFirestore.instance
            .collection('chatRoom')
            .doc(widget.groupId)
            .collection('ChatUsers')
            .doc(widget.userMap['id'])
            .collection('message')
            .doc(fileName)
            .set({
          'message': '',
          'sender': auth.currentUser!.uid,
          'receiver': widget.userMap['id'],
          'receiverFName': widget.userMap['firstName'],
          'receiverLName': widget.userMap['lastName'],
          'timeStamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'messageId': fileName,
          'messageType': MessageType.video,
          'readStatus': false,
          //'userStatus': userStatus,
          'duration': ''
        });

        var ref = FirebaseStorage.instance
            .ref()
            .child('Videos')
            .child('$fileName.mp4');

        var uploadTask =
            await ref.putFile(videoFile!).catchError((error) async {
          await FirebaseFirestore.instance
              .collection('chatRoom')
              .doc(widget.groupId)
              .collection('ChatUsers')
              .doc(auth.currentUser!.uid)
              .collection('message')
              .doc(fileName)
              .delete();

          status = 0;
        });
        if (status == 1) {
          videoUrl = await uploadTask.ref.getDownloadURL();

          print('url is ${videoUrl}');

          await FirebaseFirestore.instance
              .collection('chatRoom')
              .doc(widget.groupId)
              .collection('ChatUsers')
              .doc(auth.currentUser!.uid)
              .collection('message')
              .doc(fileName)
              .update({'message': videoUrl});
          await FirebaseFirestore.instance
              .collection('chatRoom')
              .doc(widget.groupId)
              .collection('ChatUsers')
              .doc(widget.userMap['id'])
              .collection('message')
              .doc(fileName)
              .update({'message': videoUrl});
        }

        // sendButton(mesContent: imageUrl, type: MessageType.image,);

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
                .set({
              'email': widget.userMap['email'],
              'id': widget.userMap['id'],
              'status': "offline",
              'lastMessage': 'Video',
              'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
              'password': "1234445",
              'firstName': widget.userMap['firstName'],
              'lastName': widget.userMap['lastName'],
              // 'lastName': userDetails.lastName.toString(),
            });
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
              'lastMessage': 'Video',
              'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
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

  Future getVideoGallery() async {
    ImagePicker imagePicker = ImagePicker();
    await imagePicker.getVideo(source: ImageSource.gallery).then((xFile) async {
      if (xFile != null) {
        videoFile = File(xFile.path);
        print("Video File is $videoFile");
        uploadVideo();
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

  // Image Files Ended  Here All Code Related to Image Audio ---------------------------------------------------------

  // Audio Files Start Here All Code Related to sending Audio ---------------------------------------------------------

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
              .set({
            'email': widget.userMap['email'],
            'id': widget.userMap['id'],
            'status': "offline",
            'lastMessage': 'Audio',
            'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
            'password': "1234445",
            'firstName': widget.userMap['firstName'],
            'lastName': widget.userMap['lastName'],
            // 'lastName': userDetails.lastName.toString(),
          });
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
            'lastMessage': 'Audio',
            'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
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

  // Audio Section Ended Here --------------------------------------------------------
  Widget chatBottomField() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: getHeight(50)),
      //height: 50,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                              onTap: () {
                                                loading
                                                    ? const CircularProgressIndicator()
                                                    : getImageCamera();
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
                                                Navigator.of(context).pop();
                                                showModalBottomSheet(context: context, builder: (BuildContext context) {
                                                  return SafeArea(
                                                    child: Container(
                                                      child: Wrap(
                                                        children: <Widget>[
                                                          ListTile(
                                                              leading: Icon(Icons.photo_library),
                                                              title: Text('Gallery'),
                                                              onTap: () {
                                                                Navigator.of(context).pop();
                                                              }),
                                                          ListTile(
                                                            leading: Icon(Icons.photo_camera),
                                                            title: Text('Camera'),
                                                            onTap: () {
                                                              Navigator.of(context).pop();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },);
                                                // showDialog(context: context, builder: (context) {
                                                //   return Row(children: [
                                                //     Text('Image'),
                                                //     Text('Video'),
                                                //   ],);
                                                // },);
                                                //loading
                                                  //  ? const CircularProgressIndicator()
                                                    //: getImageGallery();
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
                                    SizedBox(
                                      height: getHeight(20),
                                    ),
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
                                            GestureDetector(
                                              onTap: () async {
                                                sendButton(
                                                    mesContent: Get.find<
                                                            ChatController>()
                                                        .myLocation
                                                        .toString(),
                                                    type: MessageType.location);
                                                await FirebaseFirestore.instance
                                                    .collection("Users")
                                                    .doc(GetStorage().read(auth
                                                        .currentUser!.uid
                                                        .toString()))
                                                    .collection("myUsers")
                                                    .get()
                                                    .then((value) {
                                                  if (value.docs.contains(
                                                      widget.userMap['id'])) {
                                                    print("user is  available");
                                                  } else {
                                                    FirebaseFirestore.instance
                                                        .collection('Users')
                                                        .doc(GetStorage().read(
                                                            auth.currentUser!
                                                                .uid
                                                                .toString()))
                                                        .collection("myUsers")
                                                        .doc(widget
                                                            .userMap['id'])
                                                        .set({
                                                      'email': widget
                                                          .userMap['email'],
                                                      'id':
                                                          widget.userMap['id'],
                                                      'status': "offline",
                                                      'lastMessage': 'Location',
                                                      'lastMessageTime': DateTime
                                                              .now()
                                                          .millisecondsSinceEpoch,
                                                      'password': "1234445",
                                                      'firstName': widget
                                                          .userMap['firstName'],
                                                      'lastName': widget
                                                          .userMap['lastName'],
                                                      // 'lastName': userDetails.lastName.toString(),
                                                    });
                                                  }
                                                });
                                                await FirebaseFirestore.instance
                                                    .collection("Users")
                                                    .doc(widget.userMap['id'])
                                                    .collection("myUsers")
                                                    .get()
                                                    .then((value) {
                                                  if (value.docs.contains(
                                                      GetStorage().read(auth
                                                          .currentUser!.uid
                                                          .toString()))) {
                                                    print("user is  available");
                                                  } else {
                                                    //for (var element in value.docs) {
                                                    FirebaseFirestore.instance
                                                        .collection('Users')
                                                        .doc(widget
                                                            .userMap['id'])
                                                        .collection("myUsers")
                                                        .doc(GetStorage().read(
                                                            auth.currentUser!
                                                                .uid
                                                                .toString()))
                                                        .set({
                                                      'email': auth
                                                          .currentUser!.email,
                                                      'id':
                                                          auth.currentUser!.uid,
                                                      'status': "offline",
                                                      'lastMessage': 'Location',
                                                      'lastMessageTime': DateTime
                                                              .now()
                                                          .millisecondsSinceEpoch,
                                                      'password': "1234445",
                                                      'firstName': GetStorage()
                                                          .read(
                                                              'FirstName${auth.currentUser!.uid.toString()}'),
                                                      'lastName': GetStorage().read(
                                                          'LastName${auth.currentUser!.uid.toString()}'),
                                                      // 'lastName': userDetails.lastName.toString(),
                                                    });
                                                    // }
                                                  }
                                                  Get.back();
                                                  //await getCurrentLatLng();
                                                });
                                              },
                                              child: Container(
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
                                            GestureDetector(
                                              onTap: () {
                                                Get.to(ContactListScreen());
                                                //getVideoGallery();
                                              },
                                              child: Container(
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
                  );
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
                //filled: true,
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
                      //readStatus: false,
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
                          .set({
                        'email': widget.userMap['email'],
                        'id': widget.userMap['id'],
                        'status': "offline",
                        'password': "1234445",
                        'firstName': widget.userMap['firstName'],
                        'lastName': widget.userMap['lastName'],
                        'lastMessage': Get.find<ChatController>()
                            .chatFieldController
                            .text
                            .toString(),
                        'lastMessageTime': DateTime.now().millisecondsSinceEpoch
                      } //widget.userMap
                              );
                      FirebaseFirestore.instance
                          .collection('Users')
                          .doc(widget.userMap['id'])
                          .collection("myUsers")
                          .doc(GetStorage()
                              .read(auth.currentUser!.uid.toString()))
                          .update({
                        'lastMessage': Get.find<ChatController>()
                            .getLastMessage(widget.groupId),
                        'lastMessageTime':
                            DateTime.now().millisecondsSinceEpoch,
                      });
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
                        'lastMessage': Get.find<ChatController>()
                            .chatFieldController
                            .text
                            .toString(),
                        'lastMessageTime':
                            DateTime.now().millisecondsSinceEpoch,
                        // 'lastMessage': StreamBuilder(
                        //   stream: Get.find<ChatController>()
                        //       .getLastMessage((auth.currentUser!
                        //       .uid.hashCode +
                        //       widget.userMap['id']
                        //           .hashCode)
                        //       .toString()),
                        //   builder: (context, snapshot) {
                        //     if (snapshot.connectionState ==
                        //         ConnectionState.waiting) {
                        //       return const Center(
                        //         child:
                        //         CircularProgressIndicator(),
                        //       );
                        //     }
                        //     final data = snapshot.data!.docs;
                        //     final list = data
                        //         .map((e) =>
                        //         MessageModel.fromJson(
                        //             e))
                        //         .toList() ??
                        //         [];
                        //     //Get.log("List data is $list");
                        //     //Get.log("List data is ${list[0].receiverLName}");
                        //     if (list.isNotEmpty) {
                        //       message = list[0];
                        //       return Column(
                        //         crossAxisAlignment:
                        //         CrossAxisAlignment.start,
                        //         children: [
                        //           Row(
                        //             mainAxisAlignment:
                        //             MainAxisAlignment
                        //                 .spaceBetween,
                        //             children: [
                        //               SizedBox(
                        //                 width: getWidth(100),
                        //                 child: Text(
                        //                   maxLines: 1,
                        //                   overflow: TextOverflow
                        //                       .ellipsis,
                        //                   message != null
                        //                       ? message!.type ==
                        //                       MessageType
                        //                           .image
                        //                       ? 'Image'
                        //                       : message!.type ==
                        //                       MessageType
                        //                           .video
                        //                       ? 'Video'
                        //                       : message!.type ==
                        //                       MessageType.audio
                        //                       ? 'Audio File'
                        //                       : message!.type == MessageType.location
                        //                       ? 'Location '
                        //                       : message?.type == MessageType.text
                        //                       ? message!.messageContent
                        //                       : ""
                        //                       : "No Message",
                        //                   style: const TextStyle(
                        //                       color: MyColors
                        //                           .black),
                        //                 ),
                        //               ),
                        //               GestureDetector(
                        //                 child: Padding(
                        //                   padding:
                        //                   const EdgeInsets
                        //                       .all(8.0),
                        //                   child: Text(
                        //                     Get.find<
                        //                         HomeController>()
                        //                         .getLastMessageTime(
                        //                         context:
                        //                         context,
                        //                         time: message!
                        //                             .timestamp,
                        //                         showYear:
                        //                         false),
                        //                     style: const TextStyle(
                        //                         color: MyColors
                        //                             .black),
                        //                   ),
                        //                 ),
                        //                 onTap: () {
                        //                   // Get.find<ChatController>().getUnreadMessageLength(groupChatId: (
                        //                   //     userDetails.id.hashCode + GetStorage().read(auth.currentUser!.uid.toString())
                        //                   //         .hashCode)
                        //                   //     .toString());
                        //                 },
                        //               ),
                        //             ],
                        //           ),
                        //         ],
                        //       );
                        //     } else {
                        //       return const Text(
                        //           'No Message Here-------',
                        //           textAlign: TextAlign.left);
                        //     }
                        //   },
                        // ),
                        'firstName': GetStorage().read(
                            'FirstName${auth.currentUser!.uid.toString()}'),
                        'lastName': GetStorage().read(
                            'LastName${auth.currentUser!.uid.toString()}'),
                        // 'lastName': userDetails.lastName.toString(),
                      });

                      FirebaseFirestore.instance
                          .collection('Users')
                          .doc(auth.currentUser!.uid)
                          .collection("myUsers")
                          .doc(GetStorage()
                              .read(auth.currentUser!.uid.toString()))
                          .update({
                        'lastMessage': Get.find<ChatController>()
                            .getLastMessage(widget.groupId),
                        'lastMessageTime':
                            DateTime.now().millisecondsSinceEpoch,
                      });
                      // }
                    }
                  });
                  Get.find<ChatController>().chatFieldController.clear();
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
                  Get.find<ChatController>()
                      .updateMessageReadStatus(widget.groupId, widget.userMap);
                  Get.find<ChatController>().messagesList =
                      snapshot.data!.docs.reversed.toList();
                  if (Get.find<ChatController>().messagesList.isNotEmpty) {
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
                      controller: _scrollController,
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
          messageModel.type == MessageType.text
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onLongPress: () {
                                DialogueBox().deleteMessage(context, () {
                                  Get.find<ChatController>()
                                      .deleteSingleMessage(
                                          groupId: widget.groupId,
                                          messageId: messageModel.messageId);
                                  Get.back();
                                });

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
                                //if (widget.userMap['status']=='Offline') Icon(Icons.done,size: getHeight(15),) else Icon(Icons.done_all,size: getHeight(15),)
                                //Get.find<ChatController>().userStatus(userId: widget.userMap['id'])=='Offline'?const Icon(Icons.done):const Icon(Icons.done_all)
                                // Single Stream builder
                                // StreamBuilder(
                                //   stream: FirebaseFirestore.instance
                                //       .collection('chatRoom')
                                //       .doc(widget.groupId)
                                //       .collection('ChatUsers')
                                //       .doc(auth.currentUser!.uid)
                                //       .collection('message')
                                //       .doc(messageModel.messageId)
                                //       .snapshots(),
                                //   builder: (context, snapshot) {
                                //     if (snapshot.connectionState ==
                                //         ConnectionState.waiting) {
                                //       return const Center(
                                //         child: CircularProgressIndicator(
                                //           color: MyColors.primaryColor,
                                //         ),
                                //       );
                                //     } else {
                                //       if (snapshot.connectionState ==
                                //               ConnectionState.done ||
                                //           snapshot.connectionState ==
                                //               ConnectionState.active) {
                                //         if (snapshot.hasError) {
                                //           return Text(snapshot.error.toString());
                                //         } else {
                                //           widget.userMap['status'] == 'Online' &&
                                //                   snapshot.data!['readStatus'] ==
                                //                       false
                                //               ? Icon(Icons.done_all,
                                //                   size: getHeight(15))
                                //               : snapshot.data!['readStatus'] == true
                                //                   ? const Icon(
                                //                       Icons.done_all,
                                //                       color: Colors.blue,
                                //                     )
                                //                   : const Icon(Icons.done);
                                //         }
                                //       }
                                //     }
                                //     return const SizedBox();
                                //   },
                                // ),
                                StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(widget.userMap['id'])
                                      .snapshots(),
                                  builder: (context, snapshot1) {
                                    if (snapshot1.connectionState ==
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
                                              ConnectionState.done) {
                                        if (snapshot1.hasError) {
                                          return Text(
                                              snapshot1.error.toString());
                                        } else {
                                          return snapshot1.data!['status'] ==
                                                      'Online' &&
                                                  messageModel.readStatus ==
                                                      false
                                              ? Icon(Icons.done_all,
                                                  color: MyColors.black,
                                                  size: getHeight(15))
                                              : messageModel.readStatus == true
                                                  ? Icon(Icons.done_all,
                                                      color: MyColors.blue10,
                                                      size: getHeight(15))
                                                  : Icon(Icons.check,
                                                      size: getHeight(15));
                                        }
                                      }
                                    }
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                    // return StreamBuilder(
                                    //   stream: FirebaseFirestore.instance
                                    //       .collection('chatRoom')
                                    //       .doc(widget.groupId)
                                    //       .collection('ChatUsers')
                                    //       .doc(auth.currentUser!.uid)
                                    //       .collection('message')
                                    //       .snapshots(),
                                    //   builder: (context, snapshot2) {
                                    //     if (snapshot1.connectionState ==
                                    //             ConnectionState.waiting ||
                                    //         snapshot2.connectionState ==
                                    //             ConnectionState.waiting) {
                                    //       return const Center(
                                    //         child: CircularProgressIndicator(
                                    //           color: MyColors.primaryColor,
                                    //         ),
                                    //       );
                                    //     } else {
                                    //       if (snapshot1.connectionState ==
                                    //               ConnectionState.active ||
                                    //           snapshot1.connectionState ==
                                    //               ConnectionState.done ||
                                    //           snapshot2.connectionState ==
                                    //               ConnectionState.active ||
                                    //           snapshot2.connectionState ==
                                    //               ConnectionState.done) {
                                    //         if (snapshot1.hasError ||
                                    //             snapshot2.hasError) {
                                    //           return Text(
                                    //               snapshot1.error.toString());
                                    //         } else {
                                    //           //Get.log("Else Called  ${snapshot1.data!['status']}");
                                    //           //Get.log("Else Called  00000 ${snapshot2.data.docs['readStatus']}");
                                    //           for (var element
                                    //               in snapshot2.data!.docs) {
                                    //             return snapshot1.data![
                                    //                             'status'] ==
                                    //                         'Online' &&
                                    //                     element['readStatus'] ==
                                    //                         false
                                    //                 ? Icon(Icons.done_all,
                                    //                     color: MyColors.black,
                                    //                     size: getHeight(15))
                                    //                 : element['readStatus'] ==
                                    //                         true
                                    //                     ? Icon(
                                    //                         Icons.done_all,
                                    //                         color:
                                    //                             MyColors.blue10,
                                    //                         size: getHeight(15))
                                    //                     : Icon(Icons.check,
                                    //                         size:
                                    //                             getHeight(15));
                                    //           }
                                    //           // return snapshot1.data!['status'] ==
                                    //           // 'Online' &&
                                    //           //  snapshot2.data![
                                    //           //  'readStatus'] ==
                                    //           //     false
                                    //           // ? Icon(Icons.done_all,
                                    //           // color: MyColors.black,
                                    //           // size: getHeight(15))
                                    //           // : snapshot2.data!['readStatus'] ==
                                    //           //  true
                                    //           // ? Icon(Icons.done_all,
                                    //           // color: MyColors.blue10,
                                    //           //  size: getHeight(15))
                                    //           // : Icon(Icons.check,
                                    //           // size: getHeight(15));
                                    //         }
                                    //       }
                                    //     }
                                    //     return const SizedBox();
                                    //
                                    //     // do some stuff with both streams here
                                    //   },
                                    // );
                                  },
                                ),
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
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onLongPress: () {
                                      DialogueBox().deleteMessage(context, () {
                                        Get.find<ChatController>()
                                            .deleteSingleMessage(
                                                groupId: widget.groupId,
                                                messageId:
                                                    messageModel.messageId);
                                        Get.back();
                                      });

                                      //Get.log("Text Message is Pressed$index");
                                    },
                                    child: Container(
                                        constraints: BoxConstraints(
                                            maxWidth: getWidth(200),
                                            minHeight: getHeight(200),
                                            maxHeight: getHeight(200),
                                            minWidth: getWidth(200)),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        //height: getHeight(200),
                                        //width: getWidth(200),
                                        //decoration: BoxDecoration(color: Colors.red),
                                        child: messageModel.messageContent == ""
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                color: MyColors.primaryColor,
                                              ))
                                            : Image.network(
                                                messageModel.messageContent
                                                    .toString(),
                                                fit: BoxFit.cover,
                                                loadingBuilder:
                                                    (BuildContext context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color:
                                                          MyColors.transparent,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                    ),
                                                    width: getWidth(200),
                                                    height: getHeight(200),
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: MyColors
                                                            .primaryColor,
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
                                              )),
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
                                              .collection('chatRoom')
                                              .doc(widget.groupId)
                                              .collection('ChatUsers')
                                              .doc(auth.currentUser!.uid)
                                              .collection('message')
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
                                                  //Get.log("Else Called  ${snapshot1.data!['status']}");
                                                  //Get.log("Else Called  00000 ${snapshot2.data.docs['readStatus']}");
                                                  for (var element
                                                      in snapshot2.data!.docs) {
                                                    return snapshot1.data![
                                                                    'status'] ==
                                                                'Online' &&
                                                            element['readStatus'] ==
                                                                false
                                                        ? Icon(Icons.done_all,
                                                            color:
                                                                MyColors.black,
                                                            size: getHeight(15))
                                                        : element['readStatus'] ==
                                                                true
                                                            ? Icon(
                                                                Icons.done_all,
                                                                color: MyColors
                                                                    .blue10,
                                                                size: getHeight(
                                                                    15))
                                                            : Icon(Icons.check,
                                                                size: getHeight(
                                                                    15));
                                                  }
                                                  // return snapshot1.data!['status'] ==
                                                  // 'Online' &&
                                                  //  snapshot2.data![
                                                  //  'readStatus'] ==
                                                  //     false
                                                  // ? Icon(Icons.done_all,
                                                  // color: MyColors.black,
                                                  // size: getHeight(15))
                                                  // : snapshot2.data!['readStatus'] ==
                                                  //  true
                                                  // ? Icon(Icons.done_all,
                                                  // color: MyColors.blue10,
                                                  //  size: getHeight(15))
                                                  // : Icon(Icons.check,
                                                  // size: getHeight(15));
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
                                    //   stream: FirebaseFirestore.instance
                                    //       .collection('Users')
                                    //       .doc(widget.userMap['id'])
                                    //       .snapshots(),
                                    //   builder: (context, snapshot1) {
                                    //     return StreamBuilder(
                                    //       stream: FirebaseFirestore.instance
                                    //           .collection('chatRoom')
                                    //           .doc(widget.groupId)
                                    //           .collection('ChatUsers')
                                    //           .doc(auth.currentUser!.uid)
                                    //           .collection('message')
                                    //           .doc(messageModel.messageId)
                                    //           .snapshots(),
                                    //       builder: (context, snapshot2) {
                                    //         if (snapshot1.connectionState ==
                                    //                 ConnectionState.waiting ||
                                    //             snapshot2.connectionState ==
                                    //                 ConnectionState.waiting) {
                                    //           return const Center(
                                    //             child: CircularProgressIndicator(
                                    //               color: MyColors.primaryColor,
                                    //             ),
                                    //           );
                                    //         } else {
                                    //           if (snapshot1.connectionState ==
                                    //                   ConnectionState.active ||
                                    //               snapshot1.connectionState ==
                                    //                   ConnectionState.done ||
                                    //               snapshot2.connectionState ==
                                    //                   ConnectionState.active ||
                                    //               snapshot2.connectionState ==
                                    //                   ConnectionState.done) {
                                    //             if (snapshot1.hasError ||
                                    //                 snapshot2.hasError) {
                                    //               return Text(
                                    //                   snapshot1.error.toString());
                                    //             } else {
                                    //               return snapshot1.data![
                                    //                               'status'] ==
                                    //                           'Online' &&
                                    //                       snapshot2.data![
                                    //                               'readStatus'] ==
                                    //                           false
                                    //                   ? Icon(Icons.done_all,
                                    //                       color: MyColors.black,
                                    //                       size: getHeight(15))
                                    //                   : snapshot2.data![
                                    //                               'readStatus'] ==
                                    //                           true
                                    //                       ? Icon(
                                    //                           Icons.done_all,
                                    //                           color:
                                    //                               MyColors.blue10,
                                    //                           size: getHeight(15))
                                    //                       : Icon(Icons.check,
                                    //                           size:
                                    //                               getHeight(15));
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
                            ),
                          ],
                        )
                        //:SizedBox(height: getHeight(200),width: getWidth(200),
                        //child: const Center(child: CircularProgressIndicator(color: MyColors.primaryColor,),),),
                      ],
                    )
                  : messageModel.type == MessageType.video
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                          onLongPress: () {
                                            DialogueBox().deleteMessage(context,
                                                () {
                                              Get.find<ChatController>()
                                                  .deleteSingleMessage(
                                                      groupId: widget.groupId,
                                                      messageId: messageModel
                                                          .messageId);
                                              Get.back();
                                            });

                                            //Get.log("Text Message is Pressed$index");
                                          },
                                          child: Container(
                                              constraints: BoxConstraints(
                                                  maxWidth: getWidth(200),
                                                  minHeight: getHeight(200),
                                                  maxHeight: getHeight(200),
                                                  minWidth: getWidth(200)),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: MyColors
                                                          .primaryColor)),
                                              //height: getHeight(200),
                                              //width: getWidth(200),
                                              //decoration: BoxDecoration(color: Colors.red),
                                              child: messageModel
                                                          .messageContent ==
                                                      ""
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                      color:
                                                          MyColors.primaryColor,
                                                    ))
                                                  : Stack(children: [
                                                      //Text(messageModel.messageContent.toString()),
                                                      GestureDetector(
                                                          onTap: () {
                                                            Get.to(
                                                                VideoPlayerScreen(
                                                              url: messageModel
                                                                  .messageContent,
                                                            ));
                                                          },
                                                          child: Center(
                                                              child: Icon(
                                                            Icons.play_arrow,
                                                            size: getHeight(25),
                                                          )))
                                                    ]))),
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
                                              color: MyColors.white
                                                  .withOpacity(0.8)),
                                        ),
                                        StreamBuilder(
                                          stream: FirebaseFirestore.instance
                                              .collection('Users')
                                              .doc(widget.userMap['id'])
                                              .snapshots(),
                                          builder: (context, snapshot1) {
                                            return StreamBuilder(
                                              stream: FirebaseFirestore.instance
                                                  .collection('chatRoom')
                                                  .doc(widget.groupId)
                                                  .collection('ChatUsers')
                                                  .doc(auth.currentUser!.uid)
                                                  .collection('message')
                                                  .snapshots(),
                                              builder: (context, snapshot2) {
                                                if (snapshot1.connectionState ==
                                                        ConnectionState
                                                            .waiting ||
                                                    snapshot2.connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color:
                                                          MyColors.primaryColor,
                                                    ),
                                                  );
                                                } else {
                                                  if (snapshot1.connectionState == ConnectionState.active ||
                                                      snapshot1
                                                              .connectionState ==
                                                          ConnectionState
                                                              .done ||
                                                      snapshot2
                                                              .connectionState ==
                                                          ConnectionState
                                                              .active ||
                                                      snapshot2
                                                              .connectionState ==
                                                          ConnectionState
                                                              .done) {
                                                    if (snapshot1.hasError ||
                                                        snapshot2.hasError) {
                                                      return Text(snapshot1
                                                          .error
                                                          .toString());
                                                    } else {
                                                      //Get.log("Else Called  ${snapshot1.data!['status']}");
                                                      //Get.log("Else Called  00000 ${snapshot2.data.docs['readStatus']}");
                                                      for (var element
                                                          in snapshot2
                                                              .data!.docs) {
                                                        return snapshot1.data![
                                                                        'status'] ==
                                                                    'Online' &&
                                                                element['readStatus'] ==
                                                                    false
                                                            ? Icon(
                                                                Icons.done_all,
                                                                color: MyColors
                                                                    .black,
                                                                size:
                                                                    getHeight(
                                                                        15))
                                                            : element['readStatus'] ==
                                                                    true
                                                                ? Icon(
                                                                    Icons
                                                                        .done_all,
                                                                    color: MyColors
                                                                        .blue10,
                                                                    size:
                                                                        getHeight(
                                                                            15))
                                                                : Icon(
                                                                    Icons.check,
                                                                    size:
                                                                        getHeight(
                                                                            15));
                                                      }
                                                      // return snapshot1.data!['status'] ==
                                                      // 'Online' &&
                                                      //  snapshot2.data![
                                                      //  'readStatus'] ==
                                                      //     false
                                                      // ? Icon(Icons.done_all,
                                                      // color: MyColors.black,
                                                      // size: getHeight(15))
                                                      // : snapshot2.data!['readStatus'] ==
                                                      //  true
                                                      // ? Icon(Icons.done_all,
                                                      // color: MyColors.blue10,
                                                      //  size: getHeight(15))
                                                      // : Icon(Icons.check,
                                                      // size: getHeight(15));
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
                                        //   stream: FirebaseFirestore.instance
                                        //       .collection('Users')
                                        //       .doc(widget.userMap['id'])
                                        //       .snapshots(),
                                        //   builder: (context, snapshot1) {
                                        //     return StreamBuilder(
                                        //       stream: FirebaseFirestore.instance
                                        //           .collection('chatRoom')
                                        //           .doc(widget.groupId)
                                        //           .collection('ChatUsers')
                                        //           .doc(auth.currentUser!.uid)
                                        //           .collection('message')
                                        //           .doc(messageModel.messageId)
                                        //           .snapshots(),
                                        //       builder: (context, snapshot2) {
                                        //         if (snapshot1.connectionState ==
                                        //                 ConnectionState.waiting ||
                                        //             snapshot2.connectionState ==
                                        //                 ConnectionState.waiting) {
                                        //           return const Center(
                                        //             child: CircularProgressIndicator(
                                        //               color: MyColors.primaryColor,
                                        //             ),
                                        //           );
                                        //         } else {
                                        //           if (snapshot1.connectionState ==
                                        //                   ConnectionState.active ||
                                        //               snapshot1.connectionState ==
                                        //                   ConnectionState.done ||
                                        //               snapshot2.connectionState ==
                                        //                   ConnectionState.active ||
                                        //               snapshot2.connectionState ==
                                        //                   ConnectionState.done) {
                                        //             if (snapshot1.hasError ||
                                        //                 snapshot2.hasError) {
                                        //               return Text(
                                        //                   snapshot1.error.toString());
                                        //             } else {
                                        //               return snapshot1.data![
                                        //                               'status'] ==
                                        //                           'Online' &&
                                        //                       snapshot2.data![
                                        //                               'readStatus'] ==
                                        //                           false
                                        //                   ? Icon(Icons.done_all,
                                        //                       color: MyColors.black,
                                        //                       size: getHeight(15))
                                        //                   : snapshot2.data![
                                        //                               'readStatus'] ==
                                        //                           true
                                        //                       ? Icon(
                                        //                           Icons.done_all,
                                        //                           color:
                                        //                               MyColors.blue10,
                                        //                           size: getHeight(15))
                                        //                       : Icon(Icons.check,
                                        //                           size:
                                        //                               getHeight(15));
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
                                GestureDetector(
                                  onLongPress: () {
                                    DialogueBox().deleteMessage(context, () {
                                      Get.find<ChatController>()
                                          .deleteSingleMessage(
                                              groupId: widget.groupId,
                                              messageId:
                                                  messageModel.messageId);
                                      Get.back();
                                    });

                                    Get.log("Text Message is Pressed$index");
                                  },
                                  child: Stack(
                                    children: [
                                      audio(
                                          message: messageModel.messageContent,
                                          isCurrentUser:
                                              messageModel.currentID ==
                                                  Get.find<HomeController>()
                                                      .currentUserID,
                                          index: index,
                                          time:
                                              messageModel.timestamp.toString(),
                                          duration:
                                              messageModel.duration.toString()),
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
                                                  color: MyColors.white
                                                      .withOpacity(0.8)),
                                            ),
                                            StreamBuilder(
                                              stream: FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .doc(widget.userMap['id'])
                                                  .snapshots(),
                                              builder: (context, snapshot1) {
                                                return StreamBuilder(
                                                  stream: FirebaseFirestore
                                                      .instance
                                                      .collection('chatRoom')
                                                      .doc(widget.groupId)
                                                      .collection('ChatUsers')
                                                      .doc(
                                                          auth.currentUser!.uid)
                                                      .collection('message')
                                                      .snapshots(),
                                                  builder:
                                                      (context, snapshot2) {
                                                    if (snapshot1
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting ||
                                                        snapshot2
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: MyColors
                                                              .primaryColor,
                                                        ),
                                                      );
                                                    } else {
                                                      if (snapshot1.connectionState == ConnectionState.active ||
                                                          snapshot1
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done ||
                                                          snapshot2
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .active ||
                                                          snapshot2
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done) {
                                                        if (snapshot1
                                                                .hasError ||
                                                            snapshot2
                                                                .hasError) {
                                                          return Text(snapshot1
                                                              .error
                                                              .toString());
                                                        } else {
                                                          //Get.log("Else Called  ${snapshot1.data!['status']}");
                                                          //Get.log("Else Called  00000 ${snapshot2.data.docs['readStatus']}");
                                                          for (var element
                                                              in snapshot2
                                                                  .data!.docs) {
                                                            return snapshot1.data![
                                                                            'status'] ==
                                                                        'Online' &&
                                                                    element['readStatus'] ==
                                                                        false
                                                                ? Icon(
                                                                    Icons
                                                                        .done_all,
                                                                    color: MyColors
                                                                        .black,
                                                                    size:
                                                                        getHeight(
                                                                            15))
                                                                : element['readStatus'] ==
                                                                        true
                                                                    ? Icon(
                                                                        Icons
                                                                            .done_all,
                                                                        color: MyColors
                                                                            .blue10,
                                                                        size: getHeight(
                                                                            15))
                                                                    : Icon(
                                                                        Icons
                                                                            .check,
                                                                        size: getHeight(
                                                                            15));
                                                          }
                                                          // return snapshot1.data!['status'] ==
                                                          // 'Online' &&
                                                          //  snapshot2.data![
                                                          //  'readStatus'] ==
                                                          //     false
                                                          // ? Icon(Icons.done_all,
                                                          // color: MyColors.black,
                                                          // size: getHeight(15))
                                                          // : snapshot2.data!['readStatus'] ==
                                                          //  true
                                                          // ? Icon(Icons.done_all,
                                                          // color: MyColors.blue10,
                                                          //  size: getHeight(15))
                                                          // : Icon(Icons.check,
                                                          // size: getHeight(15));
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
                                            //   stream: FirebaseFirestore.instance
                                            //       .collection('Users')
                                            //       .doc(widget.userMap['id'])
                                            //       .snapshots(),
                                            //   builder: (context, snapshot1) {
                                            //     return StreamBuilder(
                                            //       stream: FirebaseFirestore.instance
                                            //           .collection('chatRoom')
                                            //           .doc(widget.groupId)
                                            //           .collection('ChatUsers')
                                            //           .doc(auth.currentUser!.uid)
                                            //           .collection('message')
                                            //           .doc(messageModel.messageId)
                                            //           .snapshots(),
                                            //       builder: (context, snapshot2) {
                                            //         if (snapshot1.connectionState ==
                                            //                 ConnectionState.waiting ||
                                            //             snapshot2.connectionState ==
                                            //                 ConnectionState.waiting) {
                                            //           return const Center(
                                            //             child:
                                            //                 CircularProgressIndicator(
                                            //               color: MyColors.primaryColor,
                                            //             ),
                                            //           );
                                            //         } else {
                                            //           if (snapshot1.connectionState ==
                                            //                   ConnectionState.active ||
                                            //               snapshot1.connectionState ==
                                            //                   ConnectionState.done ||
                                            //               snapshot2.connectionState ==
                                            //                   ConnectionState.active ||
                                            //               snapshot2.connectionState ==
                                            //                   ConnectionState.done) {
                                            //             if (snapshot1.hasError ||
                                            //                 snapshot2.hasError) {
                                            //               return Text(snapshot1.error
                                            //                   .toString());
                                            //             } else {
                                            //               return snapshot1.data![
                                            //                               'status'] ==
                                            //                           'Online' &&
                                            //                       snapshot2.data![
                                            //                               'readStatus'] ==
                                            //                           false
                                            //                   ? Icon(Icons.done_all,
                                            //                       color: MyColors.black,
                                            //                       size: getHeight(15))
                                            //                   : snapshot2.data![
                                            //                               'readStatus'] ==
                                            //                           true
                                            //                       ? Icon(
                                            //                           Icons.done_all,
                                            //                           color: MyColors
                                            //                               .blue10,
                                            //                           size:
                                            //                               getHeight(15))
                                            //                       : Icon(Icons.check,
                                            //                           size: getHeight(
                                            //                               15));
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
                                ),
                              ],
                            )
                          : messageModel.type == MessageType.location
                              ? Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            // onTap: (){
                                            //   Get.log("Mapped pressed");
                                            //   Get.log('lat on map is ${Get.find<ChatController>().lat!}');
                                            //   Get.log('lng on map is ${Get.find<ChatController>().long!}');
                                            //   navigateTo(lat: Get.find<ChatController>().lat! ,lng: Get.find<ChatController>().long!);
                                            // },
                                            onLongPress: () {
                                              DialogueBox()
                                                  .deleteMessage(context, () {
                                                Get.find<ChatController>()
                                                    .deleteSingleMessage(
                                                        groupId: widget.groupId,
                                                        messageId: messageModel
                                                            .messageId);
                                                Get.back();
                                              });

                                              Get.log(
                                                  "Text Message is Pressed$index");
                                            },
                                            child: Container(
                                                constraints: BoxConstraints(
                                                    maxWidth: getWidth(200),
                                                    minHeight: getHeight(200),
                                                    maxHeight: getHeight(200),
                                                    minWidth: getWidth(200)),
                                                decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                                //height: getHeight(200),
                                                //width: getWidth(200),
                                                //decoration: BoxDecoration(color: Colors.red),
                                                child: GoogleMap(
                                                  onTap: (argument) {
                                                    Get.log("Mapped pressed");
                                                    Get.log(
                                                        'lat on map is ${Get.find<ChatController>().lat!}');
                                                    Get.log(
                                                        'lng on map is ${Get.find<ChatController>().long!}');
                                                    navigateTo(
                                                        lat: Get.find<
                                                                ChatController>()
                                                            .lat!,
                                                        lng: Get.find<
                                                                ChatController>()
                                                            .long!);
                                                  },
                                                  myLocationEnabled: true,
                                                  zoomControlsEnabled: false,
                                                  zoomGesturesEnabled: false,
                                                  initialCameraPosition:
                                                      CameraPosition(
                                                    target: LatLng(
                                                        Get.find<
                                                                ChatController>()
                                                            .lat!,
                                                        Get.find<
                                                                ChatController>()
                                                            .long!),
                                                    zoom: 16,
                                                  ),
                                                )),
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
                                                  color: MyColors.white
                                                      .withOpacity(0.8)),
                                            ),
                                            StreamBuilder(
                                              stream: FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .doc(widget.userMap['id'])
                                                  .snapshots(),
                                              builder: (context, snapshot1) {
                                                return StreamBuilder(
                                                  stream: FirebaseFirestore
                                                      .instance
                                                      .collection('chatRoom')
                                                      .doc(widget.groupId)
                                                      .collection('ChatUsers')
                                                      .doc(
                                                          auth.currentUser!.uid)
                                                      .collection('message')
                                                      .snapshots(),
                                                  builder:
                                                      (context, snapshot2) {
                                                    if (snapshot1
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting ||
                                                        snapshot2
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: MyColors
                                                              .primaryColor,
                                                        ),
                                                      );
                                                    } else {
                                                      if (snapshot1.connectionState == ConnectionState.active ||
                                                          snapshot1
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done ||
                                                          snapshot2
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .active ||
                                                          snapshot2
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done) {
                                                        if (snapshot1
                                                                .hasError ||
                                                            snapshot2
                                                                .hasError) {
                                                          return Text(snapshot1
                                                              .error
                                                              .toString());
                                                        } else {
                                                          //Get.log("Else Called  ${snapshot1.data!['status']}");
                                                          //Get.log("Else Called  00000 ${snapshot2.data.docs['readStatus']}");
                                                          for (var element
                                                              in snapshot2
                                                                  .data!.docs) {
                                                            return snapshot1.data![
                                                                            'status'] ==
                                                                        'Online' &&
                                                                    element['readStatus'] ==
                                                                        false
                                                                ? Icon(
                                                                    Icons
                                                                        .done_all,
                                                                    color: MyColors
                                                                        .black,
                                                                    size:
                                                                        getHeight(
                                                                            15))
                                                                : element['readStatus'] ==
                                                                        true
                                                                    ? Icon(
                                                                        Icons
                                                                            .done_all,
                                                                        color: MyColors
                                                                            .blue10,
                                                                        size: getHeight(
                                                                            15))
                                                                    : Icon(
                                                                        Icons
                                                                            .check,
                                                                        size: getHeight(
                                                                            15));
                                                          }
                                                          // return snapshot1.data!['status'] ==
                                                          // 'Online' &&
                                                          //  snapshot2.data![
                                                          //  'readStatus'] ==
                                                          //     false
                                                          // ? Icon(Icons.done_all,
                                                          // color: MyColors.black,
                                                          // size: getHeight(15))
                                                          // : snapshot2.data!['readStatus'] ==
                                                          //  true
                                                          // ? Icon(Icons.done_all,
                                                          // color: MyColors.blue10,
                                                          //  size: getHeight(15))
                                                          // : Icon(Icons.check,
                                                          // size: getHeight(15));
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
                                            //   stream: FirebaseFirestore.instance
                                            //       .collection('Users')
                                            //       .doc(widget.userMap['id'])
                                            //       .snapshots(),
                                            //   builder: (context, snapshot1) {
                                            //     return StreamBuilder(
                                            //       stream: FirebaseFirestore.instance
                                            //           .collection('chatRoom')
                                            //           .doc(widget.groupId)
                                            //           .collection('ChatUsers')
                                            //           .doc(auth.currentUser!.uid)
                                            //           .collection('message')
                                            //           .doc(messageModel.messageId)
                                            //           .snapshots(),
                                            //       builder: (context, snapshot2) {
                                            //         if (snapshot1.connectionState ==
                                            //                 ConnectionState.waiting ||
                                            //             snapshot2.connectionState ==
                                            //                 ConnectionState.waiting) {
                                            //           return const Center(
                                            //             child: CircularProgressIndicator(
                                            //               color: MyColors.primaryColor,
                                            //             ),
                                            //           );
                                            //         } else {
                                            //           if (snapshot1.connectionState ==
                                            //                   ConnectionState.active ||
                                            //               snapshot1.connectionState ==
                                            //                   ConnectionState.done ||
                                            //               snapshot2.connectionState ==
                                            //                   ConnectionState.active ||
                                            //               snapshot2.connectionState ==
                                            //                   ConnectionState.done) {
                                            //             if (snapshot1.hasError ||
                                            //                 snapshot2.hasError) {
                                            //               return Text(
                                            //                   snapshot1.error.toString());
                                            //             } else {
                                            //               return snapshot1.data![
                                            //                               'status'] ==
                                            //                           'Online' &&
                                            //                       snapshot2.data![
                                            //                               'readStatus'] ==
                                            //                           false
                                            //                   ? Icon(Icons.done_all,
                                            //                       color: MyColors.black,
                                            //                       size: getHeight(15))
                                            //                   : snapshot2.data![
                                            //                               'readStatus'] ==
                                            //                           true
                                            //                       ? Icon(
                                            //                           Icons.done_all,
                                            //                           color:
                                            //                               MyColors.blue10,
                                            //                           size: getHeight(15))
                                            //                       : Icon(Icons.check,
                                            //                           size:
                                            //                               getHeight(15));
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
      // if (messageModel.readStatus == false) {
      //   Get.find<ChatController>()
      //      .updateMessageReadStatus(messageModel,widget.groupId, widget.userMap['id'],);
      // }
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
                  : messageModel.type == MessageType.video
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                          onLongPress: () {
                                            DialogueBox().deleteMessage(context,
                                                () {
                                              Get.find<ChatController>()
                                                  .deleteSingleMessage(
                                                      groupId: widget.groupId,
                                                      messageId: messageModel
                                                          .messageId);
                                              Get.back();
                                            });

                                            //Get.log("Text Message is Pressed$index");
                                          },
                                          child: Container(
                                              constraints: BoxConstraints(
                                                  maxWidth: getWidth(200),
                                                  minHeight: getHeight(200),
                                                  maxHeight: getHeight(200),
                                                  minWidth: getWidth(200)),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: MyColors
                                                          .primaryColor)),
                                              //height: getHeight(200),
                                              //width: getWidth(200),
                                              //decoration: BoxDecoration(color: Colors.red),
                                              child: messageModel
                                                          .messageContent ==
                                                      ""
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                      color:
                                                          MyColors.primaryColor,
                                                    ))
                                                  : Stack(children: [
                                                      //Text(messageModel.messageContent.toString()),
                                                      GestureDetector(
                                                          onTap: () {
                                                            Get.to(
                                                                VideoPlayerScreen(
                                                              url: messageModel
                                                                  .messageContent,
                                                            ));
                                                          },
                                                          child: Center(
                                                              child: Icon(
                                                            Icons.play_arrow,
                                                            size: getHeight(25),
                                                          )))
                                                    ]))),
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
                                              color: MyColors.white
                                                  .withOpacity(0.8)),
                                        ),
                                        StreamBuilder(
                                          stream: FirebaseFirestore.instance
                                              .collection('Users')
                                              .doc(widget.userMap['id'])
                                              .snapshots(),
                                          builder: (context, snapshot1) {
                                            return StreamBuilder(
                                              stream: FirebaseFirestore.instance
                                                  .collection('chatRoom')
                                                  .doc(widget.groupId)
                                                  .collection('ChatUsers')
                                                  .doc(auth.currentUser!.uid)
                                                  .collection('message')
                                                  .snapshots(),
                                              builder: (context, snapshot2) {
                                                if (snapshot1.connectionState ==
                                                        ConnectionState
                                                            .waiting ||
                                                    snapshot2.connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color:
                                                          MyColors.primaryColor,
                                                    ),
                                                  );
                                                } else {
                                                  if (snapshot1.connectionState == ConnectionState.active ||
                                                      snapshot1
                                                              .connectionState ==
                                                          ConnectionState
                                                              .done ||
                                                      snapshot2
                                                              .connectionState ==
                                                          ConnectionState
                                                              .active ||
                                                      snapshot2
                                                              .connectionState ==
                                                          ConnectionState
                                                              .done) {
                                                    if (snapshot1.hasError ||
                                                        snapshot2.hasError) {
                                                      return Text(snapshot1
                                                          .error
                                                          .toString());
                                                    } else {
                                                      //Get.log("Else Called  ${snapshot1.data!['status']}");
                                                      //Get.log("Else Called  00000 ${snapshot2.data.docs['readStatus']}");
                                                      for (var element
                                                          in snapshot2
                                                              .data!.docs) {
                                                        return snapshot1.data![
                                                                        'status'] ==
                                                                    'Online' &&
                                                                element['readStatus'] ==
                                                                    false
                                                            ? Icon(
                                                                Icons.done_all,
                                                                color: MyColors
                                                                    .black,
                                                                size:
                                                                    getHeight(
                                                                        15))
                                                            : element['readStatus'] ==
                                                                    true
                                                                ? Icon(
                                                                    Icons
                                                                        .done_all,
                                                                    color: MyColors
                                                                        .blue10,
                                                                    size:
                                                                        getHeight(
                                                                            15))
                                                                : Icon(
                                                                    Icons.check,
                                                                    size:
                                                                        getHeight(
                                                                            15));
                                                      }
                                                      // return snapshot1.data!['status'] ==
                                                      // 'Online' &&
                                                      //  snapshot2.data![
                                                      //  'readStatus'] ==
                                                      //     false
                                                      // ? Icon(Icons.done_all,
                                                      // color: MyColors.black,
                                                      // size: getHeight(15))
                                                      // : snapshot2.data!['readStatus'] ==
                                                      //  true
                                                      // ? Icon(Icons.done_all,
                                                      // color: MyColors.blue10,
                                                      //  size: getHeight(15))
                                                      // : Icon(Icons.check,
                                                      // size: getHeight(15));
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
                                        //   stream: FirebaseFirestore.instance
                                        //       .collection('Users')
                                        //       .doc(widget.userMap['id'])
                                        //       .snapshots(),
                                        //   builder: (context, snapshot1) {
                                        //     return StreamBuilder(
                                        //       stream: FirebaseFirestore.instance
                                        //           .collection('chatRoom')
                                        //           .doc(widget.groupId)
                                        //           .collection('ChatUsers')
                                        //           .doc(auth.currentUser!.uid)
                                        //           .collection('message')
                                        //           .doc(messageModel.messageId)
                                        //           .snapshots(),
                                        //       builder: (context, snapshot2) {
                                        //         if (snapshot1.connectionState ==
                                        //                 ConnectionState.waiting ||
                                        //             snapshot2.connectionState ==
                                        //                 ConnectionState.waiting) {
                                        //           return const Center(
                                        //             child: CircularProgressIndicator(
                                        //               color: MyColors.primaryColor,
                                        //             ),
                                        //           );
                                        //         } else {
                                        //           if (snapshot1.connectionState ==
                                        //                   ConnectionState.active ||
                                        //               snapshot1.connectionState ==
                                        //                   ConnectionState.done ||
                                        //               snapshot2.connectionState ==
                                        //                   ConnectionState.active ||
                                        //               snapshot2.connectionState ==
                                        //                   ConnectionState.done) {
                                        //             if (snapshot1.hasError ||
                                        //                 snapshot2.hasError) {
                                        //               return Text(
                                        //                   snapshot1.error.toString());
                                        //             } else {
                                        //               return snapshot1.data![
                                        //                               'status'] ==
                                        //                           'Online' &&
                                        //                       snapshot2.data![
                                        //                               'readStatus'] ==
                                        //                           false
                                        //                   ? Icon(Icons.done_all,
                                        //                       color: MyColors.black,
                                        //                       size: getHeight(15))
                                        //                   : snapshot2.data![
                                        //                               'readStatus'] ==
                                        //                           true
                                        //                       ? Icon(
                                        //                           Icons.done_all,
                                        //                           color:
                                        //                               MyColors.blue10,
                                        //                           size: getHeight(15))
                                        //                       : Icon(Icons.check,
                                        //                           size:
                                        //                               getHeight(15));
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
                                        duration:
                                            messageModel.duration.toString()),
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
                          : messageModel.type == MessageType.location
                              ? Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            // onTap: (){
                                            //   Get.log("Mapped pressed");
                                            //   Get.log('lat on map is ${Get.find<ChatController>().lat!}');
                                            //   Get.log('lng on map is ${Get.find<ChatController>().long!}');
                                            //   navigateTo(lat: Get.find<ChatController>().lat! ,lng: Get.find<ChatController>().long!);
                                            // },
                                            onLongPress: () {
                                              DialogueBox()
                                                  .deleteMessage(context, () {
                                                Get.find<ChatController>()
                                                    .deleteSingleMessage(
                                                        groupId: widget.groupId,
                                                        messageId: messageModel
                                                            .messageId);
                                                Get.back();
                                              });

                                              Get.log(
                                                  "Text Message is Pressed$index");
                                            },
                                            child: Container(
                                                constraints: BoxConstraints(
                                                    maxWidth: getWidth(200),
                                                    minHeight: getHeight(200),
                                                    maxHeight: getHeight(200),
                                                    minWidth: getWidth(200)),
                                                decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                                //height: getHeight(200),
                                                //width: getWidth(200),
                                                //decoration: BoxDecoration(color: Colors.red),
                                                child: GoogleMap(
                                                  onTap: (argument) {
                                                    Get.log("Mapped pressed");
                                                    Get.log(
                                                        'lat on map is ${Get.find<ChatController>().lat!}');
                                                    Get.log(
                                                        'lng on map is ${Get.find<ChatController>().long!}');
                                                    navigateTo(
                                                        lat: Get.find<
                                                                ChatController>()
                                                            .lat!,
                                                        lng: Get.find<
                                                                ChatController>()
                                                            .long!);
                                                  },
                                                  myLocationEnabled: true,
                                                  zoomControlsEnabled: false,
                                                  zoomGesturesEnabled: false,
                                                  initialCameraPosition:
                                                      CameraPosition(
                                                    target: LatLng(
                                                        Get.find<
                                                                ChatController>()
                                                            .lat!,
                                                        Get.find<
                                                                ChatController>()
                                                            .long!),
                                                    zoom: 16,
                                                  ),
                                                )),
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
                                                  color: MyColors.white
                                                      .withOpacity(0.8)),
                                            ),
                                            StreamBuilder(
                                              stream: FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .doc(widget.userMap['id'])
                                                  .snapshots(),
                                              builder: (context, snapshot1) {
                                                return StreamBuilder(
                                                  stream: FirebaseFirestore
                                                      .instance
                                                      .collection('chatRoom')
                                                      .doc(widget.groupId)
                                                      .collection('ChatUsers')
                                                      .doc(
                                                          auth.currentUser!.uid)
                                                      .collection('message')
                                                      .snapshots(),
                                                  builder:
                                                      (context, snapshot2) {
                                                    if (snapshot1
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting ||
                                                        snapshot2
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: MyColors
                                                              .primaryColor,
                                                        ),
                                                      );
                                                    } else {
                                                      if (snapshot1.connectionState == ConnectionState.active ||
                                                          snapshot1
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done ||
                                                          snapshot2
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .active ||
                                                          snapshot2
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done) {
                                                        if (snapshot1
                                                                .hasError ||
                                                            snapshot2
                                                                .hasError) {
                                                          return Text(snapshot1
                                                              .error
                                                              .toString());
                                                        } else {
                                                          //Get.log("Else Called  ${snapshot1.data!['status']}");
                                                          //Get.log("Else Called  00000 ${snapshot2.data.docs['readStatus']}");
                                                          for (var element
                                                              in snapshot2
                                                                  .data!.docs) {
                                                            return snapshot1.data![
                                                                            'status'] ==
                                                                        'Online' &&
                                                                    element['readStatus'] ==
                                                                        false
                                                                ? Icon(
                                                                    Icons
                                                                        .done_all,
                                                                    color: MyColors
                                                                        .black,
                                                                    size:
                                                                        getHeight(
                                                                            15))
                                                                : element['readStatus'] ==
                                                                        true
                                                                    ? Icon(
                                                                        Icons
                                                                            .done_all,
                                                                        color: MyColors
                                                                            .blue10,
                                                                        size: getHeight(
                                                                            15))
                                                                    : Icon(
                                                                        Icons
                                                                            .check,
                                                                        size: getHeight(
                                                                            15));
                                                          }
                                                          // return snapshot1.data!['status'] ==
                                                          // 'Online' &&
                                                          //  snapshot2.data![
                                                          //  'readStatus'] ==
                                                          //     false
                                                          // ? Icon(Icons.done_all,
                                                          // color: MyColors.black,
                                                          // size: getHeight(15))
                                                          // : snapshot2.data!['readStatus'] ==
                                                          //  true
                                                          // ? Icon(Icons.done_all,
                                                          // color: MyColors.blue10,
                                                          //  size: getHeight(15))
                                                          // : Icon(Icons.check,
                                                          // size: getHeight(15));
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
                                            //   stream: FirebaseFirestore.instance
                                            //       .collection('Users')
                                            //       .doc(widget.userMap['id'])
                                            //       .snapshots(),
                                            //   builder: (context, snapshot1) {
                                            //     return StreamBuilder(
                                            //       stream: FirebaseFirestore.instance
                                            //           .collection('chatRoom')
                                            //           .doc(widget.groupId)
                                            //           .collection('ChatUsers')
                                            //           .doc(auth.currentUser!.uid)
                                            //           .collection('message')
                                            //           .doc(messageModel.messageId)
                                            //           .snapshots(),
                                            //       builder: (context, snapshot2) {
                                            //         if (snapshot1.connectionState ==
                                            //                 ConnectionState.waiting ||
                                            //             snapshot2.connectionState ==
                                            //                 ConnectionState.waiting) {
                                            //           return const Center(
                                            //             child: CircularProgressIndicator(
                                            //               color: MyColors.primaryColor,
                                            //             ),
                                            //           );
                                            //         } else {
                                            //           if (snapshot1.connectionState ==
                                            //                   ConnectionState.active ||
                                            //               snapshot1.connectionState ==
                                            //                   ConnectionState.done ||
                                            //               snapshot2.connectionState ==
                                            //                   ConnectionState.active ||
                                            //               snapshot2.connectionState ==
                                            //                   ConnectionState.done) {
                                            //             if (snapshot1.hasError ||
                                            //                 snapshot2.hasError) {
                                            //               return Text(
                                            //                   snapshot1.error.toString());
                                            //             } else {
                                            //               return snapshot1.data![
                                            //                               'status'] ==
                                            //                           'Online' &&
                                            //                       snapshot2.data![
                                            //                               'readStatus'] ==
                                            //                           false
                                            //                   ? Icon(Icons.done_all,
                                            //                       color: MyColors.black,
                                            //                       size: getHeight(15))
                                            //                   : snapshot2.data![
                                            //                               'readStatus'] ==
                                            //                           true
                                            //                       ? Icon(
                                            //                           Icons.done_all,
                                            //                           color:
                                            //                               MyColors.blue10,
                                            //                           size: getHeight(15))
                                            //                       : Icon(Icons.check,
                                            //                           size:
                                            //                               getHeight(15));
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
}
