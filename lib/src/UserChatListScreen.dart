import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../chat/chatScreen.dart';

class UserChatListScreen extends StatefulWidget {
  @override
  State<UserChatListScreen> createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends State<UserChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _deleteChatRoom(String chatRoomId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .get()
          .then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Chats',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.deepPurple[300]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.deepPurple[300]),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chatRooms')
                    .where('userId', isEqualTo: currentUser?.uid)
                    .orderBy('lastMessageTimestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    );
                  }

                  var filteredChats = snapshot.data!.docs.where((chatRoom) {
                    var vendorName = (chatRoom['vendorName'] ?? '').toLowerCase();
                    return vendorName.contains(_searchQuery);
                  }).toList();

                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.chat_bubble_outline,
                            size: 120,
                            color: Colors.deepPurple[100],
                          ),
                          SizedBox(height: 20),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No chats found'
                                : 'No chats yet',
                            style: TextStyle(
                              color: Colors.deepPurple[300],
                              fontSize: 20,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filteredChats.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      var chatRoom = filteredChats[index];
                      var vendorName = chatRoom['vendorName'] ?? 'Vendor';
                      var vendorId = chatRoom['vendorId'];

                      return Dismissible(
                        key: Key(chatRoom.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text('Delete Chat'),
                              content: Text('Are you sure you want to delete this chat?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (direction) async {
                          String chatRoomId = chatRoom.id;
                          await _deleteChatRoom(chatRoomId);
                          setState(() {
                            filteredChats.removeAt(index);
                          });
                        },
                        child: _buildChatItem(chatRoom, vendorId, vendorName),
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

  Widget _buildChatItem(DocumentSnapshot chatRoom, String vendorId, String vendorName) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .snapshots(),
      builder: (context, vendorSnapshot) {
        if (!vendorSnapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: Text(vendorName),
              subtitle: Text('Loading vendor details...'),
            ),
          );
        }

        var vendorImageUrl = vendorSnapshot.data?.get('storeImage') ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chatRooms')
              .doc(chatRoom.id)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, messageSnapshot) {
            if (!messageSnapshot.hasData) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text(vendorName),
                  subtitle: Text('Loading last message...'),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: vendorImageUrl.isNotEmpty
                        ? NetworkImage(vendorImageUrl)
                        : AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                ),
              );
            }

            var lastMessageDoc = messageSnapshot.data!.docs.firstOrNull;
            var lastMessage = lastMessageDoc?['message'] ?? 'Chat started';
            var lastMessageTime = lastMessageDoc != null
                ? DateFormat('hh:mm a').format(
                    (lastMessageDoc['timestamp'] as Timestamp).toDate())
                : 'N/A';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatRoomId: chatRoom.id,
                          otherUserId: vendorId,
                          otherUserName: vendorName,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: vendorImageUrl.isNotEmpty
                                ? NetworkImage(vendorImageUrl)
                                : AssetImage('assets/default_profile.png') as ImageProvider,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.deepPurple[700],
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              lastMessageTime,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
