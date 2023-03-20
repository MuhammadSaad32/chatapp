import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class PaginatedDataScreen extends StatefulWidget {
  const PaginatedDataScreen({Key? key}) : super(key: key);

  @override
  State<PaginatedDataScreen> createState() => _PaginatedDataScreenState();
}

class _PaginatedDataScreenState extends State<PaginatedDataScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  DocumentSnapshot? lastDocument;
  List<Map<String,dynamic>> list =[];
  bool moreData = true;

  @override
  void initState() {
    // TODO: implement initState
    data();
  }
  void data() async {
   if(moreData){
     Query q = firestore
         .collection('chatRoom')
         .doc(555952079.toString())
         .collection('ChatUsers')
         .doc(auth.currentUser!.uid)
         .collection('message');

     late QuerySnapshot querySnapshot;
     if(lastDocument == null){
       querySnapshot = await q.limit(15).get();
     }
     else{
       querySnapshot = await q.limit(15).startAfterDocument(lastDocument!).get();
     }
     lastDocument = querySnapshot.docs.last;
     list.addAll(querySnapshot.docs.map((e) => e.data() as Map<String,dynamic>));

     if(querySnapshot.docs.length<15){
       moreData = false;

     }
     else{
        Get.log("No More Data ");
     }
   }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Paginated Data"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${list[index]['messageType']}'),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
