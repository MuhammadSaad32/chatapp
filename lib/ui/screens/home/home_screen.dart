import 'package:chat_app/controllers/chatController/chat_controller.dart';
import 'package:chat_app/controllers/homeController/home_controller.dart';
import 'package:chat_app/data/models/chatUsersModel/chat_user_model.dart';
import 'package:chat_app/data/models/user_details_model/user_detail.dart';
import 'package:chat_app/ui/screens/auth/login/login_screen.dart';
import 'package:chat_app/ui/values/ui_size_config.dart';
import 'package:chat_app/ui/widgets/dialogue_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../values/my_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/toast.dart';
import '../allusers/all_users_screen.dart';
import '../chat/chat_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

import '../video/video_play_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final fireStore = FirebaseFirestore.instance;
  double? lat;
  double? log;
  List<String> myLocation = [];
  final auth = FirebaseAuth.instance;
  MessageModel? message;

  @override
  void initState() {
    super.initState();
    GetStorage().read(auth.currentUser!.uid.toString());
    GetStorage().read('FirstName${auth.currentUser!.uid.toString()}');
    GetStorage().read('LastName${auth.currentUser!.uid.toString()}');
    GetStorage().read('email${auth.currentUser!.uid.toString()}');
    WidgetsBinding.instance.addObserver(this);

    // Get.find<HomeController>().setStatus("Online");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // online
      Get.find<HomeController>().setStatus("Online");
    } else {
      // offline
      Get.find<HomeController>().setStatus("Offline");
    }
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    //print("current id is home Screen is  ${Get.find<HomeController>().currentUserID}");
    // homeController.getAllUsers();
    SizeConfig().init(context);
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: MyColors.primaryColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: getHeight(54),
                        width: getWidth(54),
                        decoration: const BoxDecoration(
                            color: MyColors.white, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          "UN",
                          style: TextStyle(
                              color: MyColors.primaryColor,
                              fontSize: getFont(20),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      SizedBox(
                        width: getWidth(17),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${GetStorage().read('FirstName${auth.currentUser!.uid.toString()}')} ${GetStorage().read('LastName${auth.currentUser!.uid.toString()}')}',
                            // homeController.loggedInUserFirstName==null?
                            //'${Get.find<HomeController>().loggedInUserFirstName} ${Get.find<HomeController>().loggedInUserLastName}',
                            // "User Name",
                            style: TextStyle(
                                color: MyColors.white,
                                fontSize: getFont(16),
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            // GetStorage().read("email").toString(),
                            '${GetStorage().read('email${auth.currentUser!.uid.toString()}')}',
                            // "username@mail.com",
                            style: TextStyle(
                                color: MyColors.white,
                                fontSize: getFont(12),
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: MyColors.white,
                      size: 30,
                    ),
                  )
                ],
              ),
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {},
            ),
            ListTile(
              title: const Text('My Orders'),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Saved Addresses'),
              onTap: () {},
            ),
            ListTile(
              title: const Text('My Cards'),
              onTap: () {},
            ),
            SizedBox(
              height: getHeight(10),
            ),
            const Divider(),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getWidth(20), vertical: getHeight(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help Center',
                    style:
                        TextStyle(color: MyColors.black, fontSize: getFont(14)),
                  ),
                  SizedBox(
                    height: getHeight(13),
                  ),
                  Text(
                    'Privacy Policy',
                    style:
                        TextStyle(color: MyColors.black, fontSize: getFont(14)),
                  ),
                  SizedBox(
                    height: getHeight(13),
                  ),
                  Text(
                    'Terms & Conditions',
                    style:
                        TextStyle(color: MyColors.black, fontSize: getFont(14)),
                  ),
                  SizedBox(
                    height: getHeight(13),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await fireStore
                          .collection('Users')
                          .doc(GetStorage()
                              .read(auth.currentUser!.uid.toString()))
                          .update({
                        "status": "Offline",
                      });
                      auth.signOut();
                      Get.offAll(LoginScreen());
                      //homeController.usersName.clear();
                    },
                    child: Text(
                      'Logout',
                      style: TextStyle(
                          color: MyColors.black, fontSize: getFont(34)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Home Screen"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: MyColors.primaryColor,
        leading: GestureDetector(
            onTap: () {
              scaffoldKey.currentState!.openDrawer();
            },
            child: const Icon(Icons.menu_rounded)),
        actions: [
          GestureDetector(
              onTap: () {
                //Get.to(const ContactList());
              },
              child: const Icon(Icons.search)),
          SizedBox(width: getWidth(10)),
          GestureDetector(
              onTap: () {
                //Get.find<HomeController>().getDataCurrentUser();
                //Get.to(ChatScreen(name: 'Saad',));
              },
              child: const Icon(Icons.more_vert)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          backgroundColor: MyColors.primaryColor,
          onPressed: () {
            Get.to(AllUsersScreen());
          },
          child: const Icon(Icons.message),
        ),
      ),
      body: WillPopScope(
        onWillPop: () {
          return DialogueBox().showExitPopup(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder(
              stream: fireStore
                  .collection('Users')
                  .doc(GetStorage().read(auth.currentUser!.uid.toString()))
                  .collection("myUsers")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: MyColors.primaryColor,
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.done ||
                    snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data == null) {
                    return const SizedBox();
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    Get.log("no data");
                    return const Center(child: Text("No Messages here yet..."));
                  }
                  if (snapshot.hasData) {
                    Get.log("yes data");
                    return ListView.builder(
                      // reverse: false,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        // return homeBuild(context, snapshot.data?.docs[index]);
                        return GestureDetector(
                          onTap: () {
                            //Get.find<ChatController>().updateMessageReadStatus(
                              //   (auth.currentUser!.uid.hashCode +
                                // snapshot.data!.docs[index]['id'].hashCode).toString(),
                                 //snapshot.data!.docs[index].data());
                            Get.log(
                                "12321  ${snapshot.data!.docs[index].data()['id']}");
                            Get.to(ChatScreen(
                              groupId: (auth.currentUser!.uid.hashCode +
                                      snapshot.data!.docs[index]['id'].hashCode)
                                  .toString(),
                              userMap: snapshot.data!.docs[index].data(),
                            ));
                            // firstName: ,
                            // lastName: lastName,
                            // sendToUserID: sendToUserID,
                            // groupId: groupId,
                            // currentUserID: currentUserID))
                            //snapshot.data!.docs[index];
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              color: Colors.grey.withOpacity(0.3),
                              constraints:
                                  BoxConstraints(minHeight: getHeight(80)),
                              child: Row(
                                children: [
                                  SizedBox(
                                      height: getHeight(70),
                                      width: getWidth(70),
                                      child: const Icon(
                                        Icons.account_circle,
                                        size: 50,
                                      )),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${snapshot.data!.docs[index]['firstName']} ${snapshot.data!.docs[index]['lastName']}',
                                          style: const TextStyle(
                                              color: MyColors.primaryColor),
                                        ),
                                        // SizedBox(
                                        //   height: getHeight(5),
                                        // ),
                                        StreamBuilder(
                                          stream: Get.find<ChatController>()
                                              .getLastMessage((auth.currentUser!
                                                          .uid.hashCode +
                                                      snapshot
                                                          .data!
                                                          .docs[index]['id']
                                                          .hashCode)
                                                  .toString()),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            }
                                            final data = snapshot.data!.docs;
                                            final list = data
                                                    .map((e) =>
                                                        MessageModel.fromJson(
                                                            e))
                                                    .toList() ??
                                                [];
                                            //Get.log("List data is $list");
                                            //Get.log("List data is ${list[0].receiverLName}");
                                            if (list.isNotEmpty) {
                                              message = list[0];
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SizedBox(
                                                        width: getWidth(100),
                                                        child: Text(
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          message != null
                                                              ? message!.type ==
                                                                      MessageType
                                                                          .image
                                                                  ? 'Image'
                                                                  : message!.type ==
                                                                          MessageType
                                                                              .video
                                                                      ? 'Video'
                                                                      : message!.type ==
                                                                              MessageType.audio
                                                                          ? 'Audio File'
                                                                          : message!.type == MessageType.location
                                                                              ? 'Location '
                                                                              : message?.type == MessageType.text
                                                                                  ? message!.messageContent
                                                                                  : ""
                                                              : "No Message",
                                                          style: const TextStyle(
                                                              color: MyColors
                                                                  .black),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Text(
                                                            Get.find<
                                                                    HomeController>()
                                                                .getLastMessageTime(
                                                                    context:
                                                                        context,
                                                                    time: message!
                                                                        .timestamp,
                                                                    showYear:
                                                                        false),
                                                            style: const TextStyle(
                                                                color: MyColors
                                                                    .black),
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          // Get.find<ChatController>().getUnreadMessageLength(groupChatId: (
                                                          //     userDetails.id.hashCode + GetStorage().read(auth.currentUser!.uid.toString())
                                                          //         .hashCode)
                                                          //     .toString());
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            } else {
                                              return const Text(
                                                  'No Message Here-------',
                                                  textAlign: TextAlign.left);
                                            }
                                          },
                                        ),
                                        // Row(
                                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        //   children: const [
                                        //     Text('Message'),
                                        //     Text('Time'),
                                        //   ],
                                        // )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                } else {
                  return const Text("SomeThing Went Wrong");
                }
                return const SizedBox();
              }),
        ),
      ),
    );
  }

  // Widget homeBuild(BuildContext context, DocumentSnapshot? document) {
  //   if (document != null) {
  //     UserDetails userDetails = UserDetails.fromDocument(document);
  //     return Container(
  //       constraints: BoxConstraints(minHeight: getHeight(80)),
  //       decoration: const BoxDecoration(color: MyColors.transparent),
  //       margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
  //       child: TextButton(
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: <Widget>[
  //               Material(
  //                 borderRadius: const BorderRadius.all(Radius.circular(25)),
  //                 clipBehavior: Clip.hardEdge,
  //                 child: userDetails.photoUrl.isNotEmpty
  //                     ? Image.network(
  //                         userDetails.photoUrl,
  //                         fit: BoxFit.cover,
  //                         width: 50,
  //                         height: 50,
  //                         loadingBuilder: (BuildContext context, Widget child,
  //                             ImageChunkEvent? loadingProgress) {
  //                           if (loadingProgress == null) return child;
  //                           return SizedBox(
  //                             width: 50,
  //                             height: 50,
  //                             child: Center(
  //                               child: CircularProgressIndicator(
  //                                 color: MyColors.primaryColor,
  //                                 value: loadingProgress.expectedTotalBytes !=
  //                                         null
  //                                     ? loadingProgress.cumulativeBytesLoaded /
  //                                         loadingProgress.expectedTotalBytes!
  //                                     : null,
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                         errorBuilder: (context, object, stackTrace) {
  //                           return const Icon(
  //                             Icons.account_circle,
  //                             size: 50,
  //                             color: MyColors.grey,
  //                           );
  //                         },
  //                       )
  //                     : const Icon(
  //                         Icons.account_circle,
  //                         size: 50,
  //                         color: MyColors.grey,
  //                       ),
  //               ),
  //               Expanded(
  //                 child: Container(
  //                   margin: const EdgeInsets.only(left: 20),
  //                   child: StreamBuilder(
  //                     stream: Get.find<ChatController>().getLastMessage(
  //                         (userDetails.id.hashCode +
  //                                 GetStorage()
  //                                     .read(auth.currentUser!.uid.toString())
  //                                     .hashCode)
  //                             .toString()),
  //                     builder: (context, snapshot) {
  //                       final data = snapshot.data!.docs;
  //                       final list =
  //                           data.map((e) => MessageModel.fromJson(e)).toList();
  //                       //Get.log("List data is $list");
  //                       //Get.log("List data is ${list[0].receiverLName}");
  //                       if (list.isNotEmpty) {
  //                         message = list[0];
  //                         return Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               '${message!.receiverFName} ${message!.receiverLName}',
  //                               style: const TextStyle(
  //                                   color: MyColors.primaryColor),
  //                             ),
  //                             SizedBox(
  //                               height: getHeight(5),
  //                             ),
  //                             Row(
  //                               mainAxisAlignment:
  //                                   MainAxisAlignment.spaceBetween,
  //                               children: [
  //                                 SizedBox(
  //                                   width: getWidth(100),
  //                                   child: Text(
  //                                     maxLines: 1,
  //                                     overflow: TextOverflow.ellipsis,
  //                                     message != null
  //                                         ? message!.type == MessageType.image
  //                                             ? 'Image'
  //                                             : message!.type ==
  //                                                     MessageType.audio
  //                                                 ? 'Audio File'
  //                                                 : message!.type ==
  //                                                         MessageType.location
  //                                                     ? ' Location '
  //                                                     : message?.type ==
  //                                                             MessageType.text
  //                                                         ? message!
  //                                                             .messageContent
  //                                                         : ""
  //                                         : "No Message",
  //                                     style: const TextStyle(
  //                                         color: MyColors.black),
  //                                   ),
  //                                 ),
  //                                 // Text(Get.find<ChatController>().getUnreadMessageLength((userDetails.id.hashCode + GetStorage().read(auth.currentUser!.uid.toString())
  //                                 //     .hashCode)
  //                                 //     .toString()),),
  //                                 // SizedBox(width: getWidth(100),),
  //                                 GestureDetector(
  //                                   child: Text(
  //                                     Get.find<HomeController>()
  //                                         .getLastMessageTime(
  //                                             context: context,
  //                                             time: message!.timestamp,
  //                                             showYear: false),
  //                                     style: const TextStyle(
  //                                         color: MyColors.black),
  //                                   ),
  //                                   onTap: () {
  //                                     Get.find<ChatController>()
  //                                         .getUnreadMessageLength(
  //                                             groupChatId: (userDetails
  //                                                         .id.hashCode +
  //                                                     GetStorage()
  //                                                         .read(auth
  //                                                             .currentUser!.uid
  //                                                             .toString())
  //                                                         .hashCode)
  //                                                 .toString());
  //                                   },
  //                                 ),
  //                               ],
  //                             ),
  //                           ],
  //                         );
  //                       } else {
  //                         return const Center(
  //                           child: CircularProgressIndicator(),
  //                         );
  //                       }
  //                     },
  //                   ),
  //                 ),
  //               ),
  //               // message != null
  //               //     ? Text(
  //               //         HomeController.getLastMessageTime(
  //               //             context: context,
  //               //             time: message!.timestamp,
  //               //             showYear: false),
  //               //         style: const TextStyle(color: MyColors.black),
  //               //       )
  //               //     : Container(
  //               //         height: getHeight(10),
  //               //         width: getWidth(10),
  //               //
  //               //   decoration: const BoxDecoration(
  //               //     shape: BoxShape.circle,
  //               //     color: Colors.green,
  //               //   ),
  //               //       )
  //             ],
  //           ),
  //           onPressed: () async {
  //             await Get.find<HomeController>().getCurrentUserID();
  //             String id = (userDetails.id.hashCode +
  //                     Get.find<HomeController>().currentUserID.hashCode)
  //                 .toString();
  //
  //             // Get.to(
  //             //     ChatScreen(
  //             //     firstName: userDetails.firstName,
  //             //     lastName: userDetails.lastName,
  //             //     sendToUserID: userDetails.id,
  //             //     groupId: id,
  //             //     currentUserID:
  //             //         Get.find<HomeController>().currentUserID.toString())
  //             // );
  //           }),
  //     );
  //   } else {
  //     return const Center(
  //         child: Text(
  //       '1323434141',
  //       style: TextStyle(color: MyColors.black),
  //     ));
  //   }
  // }

  // Widget buildLast(BuildContext context, DocumentSnapshot? document){
  // MessageModel messageModel = MessageModel.fromJson(document!);{
  //
  // }
  // }
}
