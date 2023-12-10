import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDataMahasiswaPage extends StatefulWidget {
  @override
  _EditDataMahasiswaPageState createState() => _EditDataMahasiswaPageState();
}

class _EditDataMahasiswaPageState extends State<EditDataMahasiswaPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController npmController = TextEditingController();
  TextEditingController fakultasController = TextEditingController();
  TextEditingController jurusanController = TextEditingController();

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
      usernameController.text = userDoc['username'] as String;
      emailController.text = userDoc['email'] as String;
      npmController.text = userDoc['npm'] as String;
      fakultasController.text = userDoc['fakultas'] as String;
      jurusanController.text = userDoc['jurusan'] as String;
    });
  }

  Future<void> updateUserInfo() async {
    await _firestore.collection('accounts').doc(_auth.currentUser?.uid).update({
      'username': usernameController.text,
      'email': emailController.text,
      'npm': npmController.text,
      'fakultas': fakultasController.text,
      'jurusan': jurusanController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Data Mahasiswa'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
              ),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: npmController,
              decoration: InputDecoration(
                labelText: 'NPM',
              ),
            ),
            TextField(
              controller: fakultasController,
              decoration: InputDecoration(
                labelText: 'Fakultas',
              ),
            ),
            TextField(
              controller: jurusanController,
              decoration: InputDecoration(
                labelText: 'Jurusan',
              ),
            ),
            ElevatedButton(
              child: Text('Update Data'),
              onPressed: () async {
                await updateUserInfo();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
