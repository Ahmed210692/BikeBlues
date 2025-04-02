import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chatScreen.dart';
import '../model/Vendor_model.dart';

import 'package:intl/intl.dart';

class VendorChatListScreen extends StatelessWidget {
  final Vendor? vendor;

  const VendorChatListScreen({Key? key, this.vendor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('My Chats'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .where('vendorId', isEqualTo: vendor?.id)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No chats yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatRoom = snapshot.data!.docs[index];
              var lastMessageTime = chatRoom['lastMessageTimestamp'] != null
                  ? DateFormat('hh:mm a').format(
                  (chatRoom['lastMessageTimestamp'] as Timestamp).toDate())
                  : 'N/A';

              // Use shopName for vendor-side chat list
              var otherUserName =  chatRoom['userName'] ?? 'User';


              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue[200],
                    child: Text(
                      otherUserName[0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    otherUserName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text(
                        chatRoom['lastMessage'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 5),
                      Text(
                        lastMessageTime,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatRoomId: chatRoom.id,
                          otherUserId: chatRoom['userId'], // Change to customerId
                          otherUserName: otherUserName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}