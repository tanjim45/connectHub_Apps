
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to use messaging.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  // একই দুজনের জন্য একই chat ID তৈরি করবে।
  String chatIdFor(String otherUid) {
    if (otherUid == currentUid) {
      throw ArgumentError('You cannot chat with yourself.');
    }

    final ids = [currentUid, otherUid]..sort();
    return '${ids[0]}__${ids[1]}';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    return _users.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(
    String uid,
  ) {
    return _users.doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatsStream() {
    return _chats
        .where('participants', arrayContains: currentUid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(
    String chatId,
  ) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<String> openChat(String otherUid) async {
    final me = currentUid;
    final id = chatIdFor(otherUid);
    final ref = _chats.doc(id);

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);

      if (!existing.exists) {
        transaction.set(ref, {
          'participants': [me, otherUid]..sort(),
          'lastMessage': '',
          'lastSenderId': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = existing.data()!;
        final participants = List<String>.from(
          data['participants'] ?? const [],
        );

        if (!participants.contains(me) ||
            !participants.contains(otherUid)) {
          throw StateError('Invalid conversation participants.');
        }
      }
    });

    return id;
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final messageText = text.trim();
    if (messageText.isEmpty) return;

    final uid = currentUid;
    final chatRef = _chats.doc(chatId);

    await _db.runTransaction((transaction) async {
      final chat = await transaction.get(chatRef);

      if (!chat.exists) {
        throw StateError('Conversation not found.');
      }

      final data = chat.data()!;
      final participants = List<String>.from(
        data['participants'] ?? const [],
      );

      if (!participants.contains(uid)) {
        throw StateError('You cannot send messages to this chat.');
      }

      final messageRef = chatRef.collection('messages').doc();

      transaction.set(messageRef, {
        'senderId': uid,
        'text': messageText,
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(chatRef, {
        'lastMessage': messageText,
        'lastSenderId': uid,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
