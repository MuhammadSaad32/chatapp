import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails {
  String id;
  String firstName;
  String lastName;
  String photoUrl;
  String status;

  UserDetails({required this.id,required this.status, required this.firstName, required this.lastName,required this.photoUrl});

  Map<String, String> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'status': status,
    };
  }

  factory UserDetails.fromDocument(DocumentSnapshot doc) {
    String firstName = "";
    String lastName = "";
    String photoUrl = "";
    String status = "";
    //String nickname = "";
    try {
      firstName = doc.get('firstName');
    } catch (e) {}
    try {
      lastName = doc.get('lastName');
    } catch (e) {}try {
      status = doc.get('status');
    } catch (e) {}
    try {
      photoUrl = doc.get('photoUrl');
    } catch (e) {}
    return UserDetails(
      id: doc.id,
      firstName: firstName,
      lastName: lastName,
      photoUrl: photoUrl,
      status: status,
      // nickname: nickname,
      // aboutMe: aboutMe,
    );
  }
}
