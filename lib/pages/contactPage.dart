import 'package:chatdos/pages/chattingpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ContactPage extends StatefulWidget {
  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  String search = '';

  String getChatRoomId(String? userIdA, String userIdB) {
    if (userIdA.hashCode <= userIdB.hashCode) {
      return '$userIdA-$userIdB';
    } else {
      return '$userIdB-$userIdA';
    }
  }

  void createChatRoom(String userIdA, String userIdB) {
    String chatRoomId = getChatRoomId(userIdA, userIdB);
    FirebaseFirestore.instance.collection('chatrooms').doc(chatRoomId).set({
      'members': [userIdA, userIdB],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Cari berdasarkan username atau npm",
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('accounts').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // pisahkan dosen dan mahasiswa
                final dosenDocs = snapshot.data?.docs
                    .where((doc) =>
                        doc['role'] == 'dosen' &&
                        doc['username']
                            .toLowerCase()
                            .contains(search.toLowerCase()))
                    .toList();
                final mahasiswaDocs = snapshot.data?.docs
                    .where((doc) =>
                        doc['role'] == 'mahasiswa' &&
                        (doc['username']
                                .toLowerCase()
                                .contains(search.toLowerCase()) ||
                            (doc['npm'] ?? '').contains(search)))
                    .toList();

                return ListView(
                  children: [
                    ListTile(
                        title: Text('Dosen',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    ...dosenDocs!
                        .map((doc) => ListTile(
                              leading: (doc['profile'] != null &&
                                      doc['profile'].isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(doc['profile']),
                                      radius: 30)
                                  : Icon(Icons.account_circle, size: 60),
                              title: Text(doc['username']),
                              subtitle:
                                  Text(doc['free'] ? 'Tidak Sibuk' : 'Sibuk'),
                              onTap: () {
                                if (FirebaseAuth.instance.currentUser?.uid != doc.id) {
                                    String chatRoomId = getChatRoomId(
                                        FirebaseAuth.instance.currentUser?.uid,
                                        doc.id);
                                    createChatRoom(
                                        FirebaseAuth.instance.currentUser!.uid,
                                        doc.id);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ChattingPage(chatRoomId: chatRoomId)),
                                    );
                                }
                              },
                            ))
                        .toList(),
                    ListTile(
                        title: Text('Mahasiswa',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    ...mahasiswaDocs!
                        .map((doc) => ListTile(
                              leading: (doc['profile'] != null &&
                                      doc['profile'].isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(doc['profile']),
                                      radius: 30)
                                  : Icon(Icons.account_circle, size: 60),
                              title: Text(doc['username']),
                              subtitle: Text(doc['npm'] ?? 'Belum Input NPM'),
                              onTap: () {
                                if (FirebaseAuth.instance.currentUser?.uid != doc.id) {
                                    String chatRoomId = getChatRoomId(
                                        FirebaseAuth.instance.currentUser?.uid,
                                        doc.id);
                                    createChatRoom(
                                        FirebaseAuth.instance.currentUser!.uid,
                                        doc.id);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ChattingPage(chatRoomId: chatRoomId)),
                                    );
                                }
                              },
                            ))
                        .toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
