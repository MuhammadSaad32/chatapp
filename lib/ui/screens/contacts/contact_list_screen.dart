import 'package:chat_app/ui/values/my_colors.dart';
import 'package:chat_app/ui/values/ui_size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';

class ContactListScreen extends StatefulWidget {
 // Query<Map<String, dynamic>> collection = FirebaseFirestore.instance
     // .collection("chat")
     // .where('id', isNotEqualTo: FirebaseAuth.instance.currentUser!.uid);
   const ContactListScreen({Key? key}) : super(key: key);

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  bool isLoading = true;
  List<Contact> contacts = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getContactPermission();
  }
  void getContactPermission() async {
    if (await Permission.contacts.isGranted) {
      fetchContacts();
    } else {
      await Permission.contacts.request();
    }
  }

  void fetchContacts() async {
    contacts = await ContactsService.getContacts();
    setState(() {
      isLoading = false;
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.primaryColor,
        title: const Text('Conatct List'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount:contacts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Container(
                    height: getHeight(30),
                    width: getWidth(30),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: MyColors.primaryColor,
                    ),
                    child: Text(
                      //'C',
                     contacts[index].displayName![0],
                      style: const TextStyle(
                        fontSize: 23,
                        color: MyColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  title: Text(
                    //'Contact',
                    contacts[index].displayName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    // '0302300203',
                    contacts[index].phones![0].value!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xffC4c4c4),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  horizontalTitleGap: 12,
                );
              } //body: StreamBuilder(builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {  },),
              ),
    );
  }
}
