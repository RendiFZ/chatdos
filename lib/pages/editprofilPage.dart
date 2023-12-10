import 'dart:io';
import 'package:chatdos/pages/EditDataDosenPage.dart';
import 'package:chatdos/pages/EditDataMahasiswaPage.dart';
import 'package:chatdos/pages/homePages.dart';
import 'package:chatdos/pages_auth/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _imageFile;
  final picker = ImagePicker();

  String? username;
  String? email;
  bool? isFree;
  bool isLoading = false;
  String? profilePicUrl;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    DocumentSnapshot userDoc = await _firestore
        .collection('accounts')
        .doc(_auth.currentUser?.uid)
        .get();
    setState(() {
      username = userDoc['username'] as String?;
      email = userDoc['email'] as String?;
      isFree = userDoc['free'] as bool?;
      profilePicUrl = userDoc['profile'] as String?;
    });
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
        uploadImage();
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      TaskSnapshot snapshot = await _storage
          .ref('profile/profile_${_auth.currentUser?.uid}.png')
          .putFile(_imageFile!);
      if (snapshot.state == TaskState.success) {
        final String downloadURL = await snapshot.ref.getDownloadURL();

        await _firestore
            .collection('accounts')
            .doc(_auth.currentUser?.uid)
            .update({
          'profile': downloadURL,
        });
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      isLoading = false;
    });

    fetchUserInfo();
  }

  Future<void> toggleFree() async {
    await _firestore.collection('accounts').doc(_auth.currentUser?.uid).update({
      'free': !isFree!,
    });

    fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    bool isDosen = _auth.currentUser?.email?.endsWith('@dosen.unsil.ac.id') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profil'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 80,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : profilePicUrl != null
                                  ? NetworkImage(profilePicUrl!)
                                  : AssetImage(
                                          'assets/images/default_profile_icon.png')
                                      as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.edit),
                            color: Colors.red,  
                            onPressed: pickImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(child: Text('Username: $username', style: TextStyle(fontSize: 20))),
                  Center(child: Text('Email: $email', style: TextStyle(fontSize: 20))),
                  SizedBox(height: 20),
                  if (isDosen)
                    Center(
                      child: ElevatedButton(
                        child: Text('Edit Data Dosen'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditDataDosenPage()),
                          );
                        },
                      ),
                    ),
                  if (isDosen)
                    Center(
                      child: SwitchListTile(
                        title: Text('Sibuk'),
                        value: isFree != true,
                        onChanged: (bool value) {
                          toggleFree();
                        },
                      ),
                    ),
                  if (!isDosen)
                    Center(
                      child: ElevatedButton(
                        child: Text('Edit Data Mahasiswa'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditDataMahasiswaPage()),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        ElevatedButton(
                          child: Text('Logout'),
                          onPressed: () async {
                            await _auth.signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
