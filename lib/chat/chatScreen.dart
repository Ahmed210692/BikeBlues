import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../model/Vendor_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  String vendorImageUrl = '';
  bool isVendor = false;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    try {
      DocumentSnapshot vendorDoc = await _firestore
          .collection('vendors')
          .doc(widget.otherUserId)
          .get();

      if (vendorDoc.exists) {
        setState(() {
          isVendor = true;
          vendorImageUrl = vendorDoc['storeImage'] ?? '';
        });
      }
    } catch (e) {
      print('Error checking user type: $e');
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        await _uploadImage(imageFile);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image. Please try again.')),
      );
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      String fileName = 'images/${widget.chatRoomId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      await storageRef.putFile(imageFile);
      final String imageUrl = await storageRef.getDownloadURL();

      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': widget.otherUserName,
        'receiverId': widget.otherUserId,
        'message': '',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'image',
      });
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (isVendor && vendorImageUrl.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(vendorImageUrl),
                        ),
                      ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUserName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat Messages
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chatRooms')
                        .doc(widget.chatRoomId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: EdgeInsets.all(16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var message = snapshot.data!.docs[index];
                          bool isMe = message['senderId'] == _auth.currentUser!.uid;
                          return _buildMessageItem(message, isMe);
                        },
                      );
                    },
                  ),
                ),
              ),
              _buildMessageInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(DocumentSnapshot message, bool isMe) {
    return GestureDetector(
      onLongPress: () => _confirmDeleteMessage(message.id),
      child: Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: isVendor ? NetworkImage(vendorImageUrl) : null,
                child: !isVendor ? Icon(Icons.person) : null,
              ),
              SizedBox(width: 8),
            ],
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message),
                  SizedBox(height: 4),
                  Text(
                    message['timestamp'] != null
                        ? DateFormat('hh:mm a').format(
                            (message['timestamp'] as Timestamp).toDate())
                        : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteMessage(messageId);
              Navigator.of(context).pop();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message. Please try again.')),
      );
    }
  }

  Widget _buildMessageContent(DocumentSnapshot message) {
    if (message.data() != null &&
        (message.data() as Map<String, dynamic>).containsKey('imageUrl') &&
        message['imageUrl'] != null &&
        message['imageUrl'] != '') {
      return GestureDetector(
        onTap: () => _showFullImageDialog(message['imageUrl']),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            message['imageUrl'],
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.error);
            },
          ),
        ),
      );
    }
    return Text(
      message['message'] ?? '',
      style: TextStyle(fontSize: 16),
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image, color: Colors.blue[700]),
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': widget.otherUserName,
        'receiverId': widget.otherUserId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    }
  }
}