import 'dart:async';

import 'package:chat_app/ui/screens/allusers/search_screen.dart';
import 'package:chat_app/ui/screens/home/home_screen.dart';
import 'package:chat_app/ui/values/ui_size_config.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/homeController/home_controller.dart';
import '../../../data/models/user_details_model/user_detail.dart';
import '../../values/my_colors.dart';
import '../../widgets/custom_textField.dart';
import '../chat/chat_screen.dart';

class AllUsersScreen extends StatefulWidget {

  AllUsersScreen({Key? key}) : super(key: key);

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final fireStore = FirebaseFirestore.instance;

  final auth = FirebaseAuth.instance;

  bool idPresent = false;
  List searchResult = [];

  void searchFromFirebase(String query) async {
    final result = await FirebaseFirestore.instance
        .collection('Users').where('id',isNotEqualTo: auth.currentUser!.uid.toString())
        .where('lastName', arrayContains: query)
        .get();

    setState(() {
      // Get.log("Result value is $result");
      searchResult = result.docs.map((e) => e.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select User",
                style: TextStyle(color: Colors.white, fontSize: getFont(16)),
              ),
              SizedBox(
                height: getHeight(4),
              ),
              StreamBuilder(
                  // stream: Get.find<HomeController>().getAllUsers(),
                  stream: fireStore
                      .collection('Users')
                      .where('id', isNotEqualTo: auth.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: MyColors.primaryColor,
                        ),
                      );
                    } if (snapshot.connectionState ==
                            ConnectionState.active ||
                        snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      } else {
                        return Text(
                          "${snapshot.data!.docs.length} Users",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: getFont(14),
                          ),
                        );
                      }
                    }
                    return const Text("SomeThing Went Wrong");
                  })
            ],
          ),
          //centerTitle: true,
          leading: GestureDetector(
              onTap: () async {
                await Get.find<HomeController>().getCurrentUserID();
                await Get.find<HomeController>().getDataCurrentUser();
                Get.offAll(HomeScreen());
              },
              child: const Icon(Icons.arrow_back)),
          backgroundColor: MyColors.primaryColor,
          actions: [
            GestureDetector(
                onTap: () {
                  // Get.to(const SearchScreen());
                },
                child: const Icon(Icons.search)),
            SizedBox(width: getWidth(10)),
            GestureDetector(
                onTap: () {
                  //homeController.getCurrentUserID();
                  //Get.to(ChatScreen(name: 'Saad',));
                },
                child: const Icon(Icons.more_vert)),
          ],
        ),
        body: StreamBuilder(
                // stream: Get.find<HomeController>().getAllUsers(),
                stream: fireStore
                    .collection('Users')
                    .where('id', isNotEqualTo: auth.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: MyColors.primaryColor,
                      ),
                    );
                  } else if (snapshot.connectionState == ConnectionState.active ||
                      snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    } else {
                          return ListView.builder(
                            // reverse: false,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              // return homeBuild(context, snapshot.data?.docs[index]);
                              return GestureDetector(
                                onTap: (){
                                  Get.log("1111111${snapshot.data!.docs[index].data()}");
                                  Get.to(ChatScreen(
                                    groupId: (auth.currentUser!.uid.hashCode + snapshot.data!.docs[index]['id'].hashCode).toString(),
                                    userMap: snapshot.data!.docs[index].data(),
                                  ));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    color: Colors.grey.withOpacity(0.3),
                                    constraints: BoxConstraints(
                                        minHeight: getHeight(80)
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                            height:getHeight(70),
                                            width: getWidth(70),
                                            child: const Icon(Icons.account_circle,size: 50,)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${snapshot.data!.docs[index]['firstName']} ${snapshot.data!.docs[index]['lastName']}'),
                                              SizedBox(height: getHeight(5),),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: const [
                                                  Text('Message'),
                                                  //Text('Time'),
                                                ],
                                              ),
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
                  }
                  return const Text("SomeThing Went Wrong");
                }),
          );
  }

  // Widget allUserBuild(BuildContext context, DocumentSnapshot? document) {
  //   if (document != null) {
  //     UserDetails userDetails = UserDetails.fromDocument(document);
  //     return Container(
  //       decoration: const BoxDecoration(color: MyColors.transparent),
  //       margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
  //       child: TextButton(
  //           child: Row(
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
  //               Flexible(
  //                 child: Container(
  //                   margin: const EdgeInsets.only(left: 20),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: <Widget>[
  //                       Text(
  //                         '${userDetails.firstName} ${userDetails.lastName}',
  //                         style: const TextStyle(color: MyColors.primaryColor),
  //                       ),
  //                       SizedBox(
  //                         height: getHeight(5),
  //                       ),
  //                       const Text(
  //                         "Message",
  //                         style: TextStyle(color: MyColors.primaryColor),
  //                       )
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           onPressed: () async {
  //             await Get.find<HomeController>().getCurrentUserID();
  //             await Get.find<HomeController>().getDataCurrentUser();
  //             String id = (userDetails.id.hashCode +
  //                     Get.find<HomeController>().currentUserID.hashCode)
  //                 .toString();
  //             // await FirebaseFirestore.instance
  //             //     .collection("Users")
  //             //     .doc(Get.find<HomeController>().currentUserID.toString())
  //             //     .collection("myUsers")
  //             //     .get()
  //             //     .then((value) {
  //             //   if (value.docs.contains(userDetails.id)) {
  //             //     print("user is  available");
  //             //   } else {
  //             //     FirebaseFirestore.instance
  //             //         .collection('Users')
  //             //         .doc(Get.find<HomeController>().currentUserID.toString())
  //             //         .collection("myUsers").doc(userDetails.id)
  //             //         .set({
  //             //       'groupId': id,
  //             //       'senderId': Get.find<HomeController>().currentUserID.toString(),
  //             //       'receiverId': userDetails.id,
  //             //       'firstName': userDetails.firstName,
  //             //       'lastName': userDetails.lastName,
  //             //     });
  //             //   }
  //             // });
  //             // await FirebaseFirestore.instance
  //             //     .collection("Users")
  //             //     .doc(Get.find<HomeController>().currentUserID.toString())
  //             //     .collection("myUsers")
  //             //     .get().then((value) {
  //             //   if (value.docs.contains(Get.find<HomeController>().currentUserID.toString())) {
  //             //     print("user is  available");
  //             //   }
  //             //   else{
  //             //     //for (var element in value.docs) {
  //             //     FirebaseFirestore.instance
  //             //         .collection('Users')
  //             //         .doc(userDetails.id)
  //             //         .collection("myUsers").doc(Get.find<HomeController>().currentUserID.toString())
  //             //         .set({
  //             //       'groupId': id,
  //             //       'senderId': userDetails.id,
  //             //       'receiverId': Get.find<HomeController>().currentUserID.toString(),
  //             //       //'firstName':userDetails.firstName.toString(),
  //             //       'firstName': Get.find<HomeController>().loggedInUserFirstName.toString(),
  //             //       'lastName':Get.find<HomeController>().loggedInUserLastName.toString(),
  //             //       // 'lastName': userDetails.lastName.toString(),
  //             //     });
  //             //     // }
  //             //   }
  //             // });
  //             Get.to(ChatScreen(
  //                 firstName: userDetails.firstName,
  //                 lastName: userDetails.lastName,
  //                 sendToUserID: userDetails.id,
  //                 groupId: id,
  //                 currentUserID: Get.find<HomeController>().currentUserID.toString())
  //             );
  //           }),
  //     );
  //   } else {
  //     return const SizedBox.shrink();
  //   }
  // }
}
