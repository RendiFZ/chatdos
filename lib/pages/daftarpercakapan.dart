import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatdos/pages/chattingpage.dart';

class ConversationListPage extends StatefulWidget {
  @override
  _ConversationListPageState createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Percakapan'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chatrooms').where('members', arrayContains: FirebaseAuth.instance.currentUser?.uid).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
  children: snapshot.data!.docs.map((doc) {
    // Dapatkan ID pengguna lain
    String otherUserId = doc['members'].firstWhere((userId) => userId != FirebaseAuth.instance.currentUser?.uid);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('accounts').doc(otherUserId).get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return ListTile(title: Text('Terjadi kesalahan'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text('Loading...'));
        }

        return ListTile(
          leading: (snapshot.data!['profile'] != null && snapshot.data!['profile'].isNotEmpty) 
            ? CircleAvatar(backgroundImage: NetworkImage(snapshot.data!['profile']), radius: 30) 
            : Icon(Icons.account_circle, size: 60),
          title: Text(snapshot.data!['username']),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChattingPage(chatRoomId: doc.id)),
            );
          },
        );
      },
    );
  }).toList(),
);

        },
      ),
    );
  }
}
