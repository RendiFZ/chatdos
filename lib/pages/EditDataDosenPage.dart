import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDataDosenPage extends StatefulWidget {
  @override
  _EditDataDosenPageState createState() => _EditDataDosenPageState();
}

class _EditDataDosenPageState extends State<EditDataDosenPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController npdController = TextEditingController();
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
      npdController.text = userDoc['npd'] as String;
      fakultasController.text = userDoc['fakultas'] as String;
      jurusanController.text = userDoc['jurusan'] as String;
    });
  }

  Future<void> updateUserInfo() async {
    await _firestore.collection('accounts').doc(_auth.currentUser?.uid).update({
      'username': usernameController.text,
      'email': emailController.text,
      'npd': npdController.text,
      'fakultas': fakultasController.text,
      'jurusan': jurusanController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Data Dosen'),
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
              controller: npdController,
              decoration: InputDecoration(
                labelText: 'NPD',
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
