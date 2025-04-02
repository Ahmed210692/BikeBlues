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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Chats',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[500],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
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
                          size: 100,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 20),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No chats found'
                              : 'No chats yet',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredChats.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    var chatRoom = filteredChats[index];
                    var vendorName = chatRoom['vendorName'] ?? 'Vendor';
                    var vendorId = chatRoom['vendorId'];

                    return Dismissible(
                      key: Key(chatRoom.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              AlertDialog(
                                title: Text('Delete Chat'),
                                content:
                                Text(
                                    'Are you sure you want to delete this chat?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        ) ??
                            false;
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
    );
  }

  Widget _buildChatItem(DocumentSnapshot chatRoom, String vendorId,
      String vendorName) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .snapshots(),
      builder: (context, vendorSnapshot) {
        if (!vendorSnapshot.hasData) {
          return ListTile(
            title: Text(vendorName),
            subtitle: Text('Loading vendor details...'),
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
              return ListTile(
                title: Text(vendorName),
                subtitle: Text('Loading last message...'),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: vendorImageUrl.isNotEmpty
                      ? NetworkImage(vendorImageUrl)
                      : AssetImage(
                      'assets/default_profile.png') as ImageProvider,
                ),
              );
            }

            var lastMessageDoc = messageSnapshot.data!.docs.firstOrNull;
            var lastMessage = lastMessageDoc?['message'] ?? 'Chat started';
            var lastMessageTime = lastMessageDoc != null
                ? DateFormat('hh:mm a').format(
                (lastMessageDoc['timestamp'] as Timestamp).toDate())
                : 'N/A';

            return ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: vendorImageUrl.isNotEmpty
                    ? NetworkImage(vendorImageUrl)
                    : AssetImage('assets/default_profile.png') as ImageProvider,
              ),
              title: Text(vendorName),
              subtitle: Text(lastMessage),
              trailing: Text(lastMessageTime),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(
                          chatRoomId: chatRoom.id,
                          otherUserId: vendorId,
                          otherUserName: vendorName,
                        ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
