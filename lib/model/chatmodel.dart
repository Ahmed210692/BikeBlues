import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final bool isRead;

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      senderId: data['senderId'],
      senderName: data['senderName'],
      receiverId: data['receiverId'],
      message: data['message'],
      timestamp: data['timestamp'],
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}

class ChatRoom {
  final String chatRoomId;
  final String userId;
  final String vendorId;
  final String userName;
  final String vendorName;
  final Timestamp lastMessageTimestamp;
  final String lastMessage;

  ChatRoom({
    required this.chatRoomId,
    required this.userId,
    required this.vendorId,
    required this.userName,
    required this.vendorName,
    required this.lastMessageTimestamp,
    required this.lastMessage,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      chatRoomId: doc.id,
      userId: data['userId'],
      vendorId: data['vendorId'],
      userName: data['userName'],
      vendorName: data['vendorName'],
      lastMessageTimestamp: data['lastMessageTimestamp'],
      lastMessage: data['lastMessage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'vendorId': vendorId,
      'userName': userName,
      'vendorName': vendorName,
      'lastMessageTimestamp': lastMessageTimestamp,
      'lastMessage': lastMessage,
    };
  }
}