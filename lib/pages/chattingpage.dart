import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // import package intl

class ChattingPage extends StatefulWidget {
  final String chatRoomId;

  ChattingPage({required this.chatRoomId});

  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  final TextEditingController messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void sendMessage(String chatRoomId, String message, {String? filePath}) {
    FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': FirebaseAuth.instance.currentUser?.uid,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [FirebaseAuth.instance.currentUser?.uid],
      'filePath': filePath, // Tambahkan field 'filePath' ini
    });
  }

  void markAsRead(DocumentSnapshot doc) {
    if (!doc['readBy'].contains(FirebaseAuth.instance.currentUser?.uid)) {
      FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(doc.id)
          .update({
        'readBy':
            FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid]),
      });
    }
  }

  Future<String?> uploadFile(XFile file) async {
    File _file = File(file.path);
    try {
      await FirebaseStorage.instance
          .ref('storage/file/${Path.basename(_file.path)}') // Ubah baris ini
          .putFile(_file);
    } on FirebaseException catch (e) {
      print(e);
    }
    String downloadURL = await FirebaseStorage.instance
        .ref('storage/file/${Path.basename(_file.path)}') // Dan ubah baris ini
        .getDownloadURL();
    return downloadURL;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Room'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatrooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    markAsRead(doc);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('accounts')
                          .doc(doc['senderId'])
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return ListTile(title: Text('Terjadi kesalahan'));
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(title: Text('Loading...'));
                        }

                        List<Icon> readIcons = [];
                        if (doc['readBy'].length > 1) {
                          readIcons.add(Icon(Icons.check,
                              color: const Color.fromARGB(255, 0, 0, 0)));
                          readIcons.add(Icon(Icons.check,
                              color: const Color.fromARGB(255, 0, 0, 0)));
                        } else if (doc['readBy'].length == 1) {
                          readIcons.add(Icon(Icons.check,
                              color: const Color.fromARGB(255, 0, 0, 0)));
                        }

                        return ListTile(
                          leading: (snapshot.data!['profile'] != null &&
                                  snapshot.data!['profile'].isNotEmpty)
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(snapshot.data!['profile']),
                                  radius: 30)
                              : Icon(Icons.account_circle, size: 60),
                          title: Text(snapshot.data!['username'],
                              style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors
                                      .black)), // warna font username hitam
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['message'],
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors
                                          .black)), // warna font pesan hitam
                              Text(
                                  'Sent at ${DateFormat('yyyy-MM-dd HH').format(doc['timestamp'].toDate())}',
                                  style: TextStyle(
                                      fontSize: 12.0)), // format waktu
                              Row(
                                children: [
                                  Text(doc['readBy'].contains(FirebaseAuth
                                          .instance.currentUser?.uid)
                                      ? 'Read'
                                      : 'Sent'),
                                  ...readIcons,
                                ],
                              ),
                              if (doc['filePath'] != null)
                                ElevatedButton(
                                  onPressed: () async {
                                    await canLaunch(doc['filePath'])
                                        ? await launch(doc['filePath'])
                                        : throw 'Could not launch ${doc['filePath']}';
                                  },
                                  child: Text('Download File'),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: "Type your message here",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    sendMessage(widget.chatRoomId, messageController.text);
                    messageController.clear();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () async {
                    final XFile? file =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (file != null) {
                      String? filePath = await uploadFile(file);
                      sendMessage(widget.chatRoomId, 'File attached',
                          filePath: filePath);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
