import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chatScreen.dart';
import '../model/Vendor_model.dart';
import 'package:intl/intl.dart';

class VendorChatListScreen extends StatefulWidget {
  final Vendor? vendor;

  const VendorChatListScreen({Key? key, this.vendor}) : super(key: key);

  @override
  _VendorChatListScreenState createState() => _VendorChatListScreenState();
}

class _VendorChatListScreenState extends State<VendorChatListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(30, 30, 30, 1),
              Color.fromRGBO(25, 25, 25, 1),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Chats',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF53DDA3)),
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                cursorColor: Color(0xFF53DDA3),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chatRooms')
                    .where('vendorId', isEqualTo: widget.vendor?.id)
                    .orderBy('lastMessageTimestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF53DDA3)),
                      ),
                    );
                  }

                  var filteredChats = snapshot.data!.docs.where((doc) {
                    String userName = (doc['userName'] ?? '').toLowerCase();
                    String lastMessage = (doc['lastMessage'] ?? '').toLowerCase();
                    return userName.contains(searchQuery) || 
                           lastMessage.contains(searchQuery);
                  }).toList();

                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.white24
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No chats found',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      var chatRoom = filteredChats[index];
                      var lastMessageTime = chatRoom['lastMessageTimestamp'] != null
                          ? DateFormat('hh:mm a').format(
                              (chatRoom['lastMessageTimestamp'] as Timestamp).toDate())
                          : 'N/A';

                      var otherUserName = chatRoom['userName'] ?? 'User';

                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFF53DDA3),
                            child: Text(
                              otherUserName[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          title: Text(
                            otherUserName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chatRoom['lastMessage'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14
                                  ),
                                ),
                              ),
                              Text(
                                lastMessageTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatRoomId: chatRoom.id,
                                  otherUserId: chatRoom['userId'],
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
            ),
          ],
        ),
      ),
    );
  }
}