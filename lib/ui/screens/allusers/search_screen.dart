import 'package:chat_app/ui/values/my_colors.dart';
import 'package:chat_app/ui/values/ui_size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String textSearch ="";
  TextEditingController searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: TextFormField(
          textInputAction: TextInputAction.search,
          controller: searchController,
          onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  textSearch = value;
                });
              } else {
                setState(() {
                  textSearch = "";
                });
            }
          },
          decoration: const InputDecoration.collapsed(
            hintText: 'Search',
            hintStyle: TextStyle(fontSize: 13, color: MyColors.primaryColor),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        leading: GestureDetector(
            onTap: (){
              Get.back();
            },
            child: const Icon(Icons.arrow_back,color: MyColors.black,)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: getHeight(20),
          ),
          // Expanded(child: )
        ],
      ),
    );
  }
}
