import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ExpenseList extends StatelessWidget {
  // FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference collection = FirebaseFirestore.instance.collection("Users");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: collection.snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Text("There is no data");
            }
            return ListView(children: getData(snapshot));
          })
    );
  }
  getData(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data!.docs
        .map((doc) => ListTile(title: Text(doc["firstName"]), subtitle: Text(doc["lastName"].toString())))
        .toList();
  }
}