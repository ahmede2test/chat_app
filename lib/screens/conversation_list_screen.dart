import 'package:chat_app/screens/my_profile_screen.dart';
import 'package:chat_app/screens/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/image_view_screen.dart'; // Import the ImageViewScreen
import '../services/chat_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  int _selectedIndex = 0; // The currently selected tab index

  static final List<Widget> _widgetOptions = <Widget>[
    _ConversationList(),
    const UsersListScreen(),
    const MyProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _signOut() async {
    await _auth.signOut();
  }

  // Build the list of conversations
  Widget _buildConversationList() => StreamBuilder<QuerySnapshot>(
      stream: _chatService.getChatRooms(_auth.currentUser!.uid),
      builder: (context, chatRoomsSnapshot) {
        if (chatRoomsSnapshot.hasError) {
          return const Center(child: Text('Something went wrong.'));
        }
        if (chatRoomsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        if (!chatRoomsSnapshot.hasData || chatRoomsSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Initiate Conversation 💬',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          itemCount: chatRoomsSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chatRoomData = chatRoomsSnapshot.data!.docs[index].data() as Map<String, dynamic>;
            final lastMessage = chatRoomData['lastMessage'] ?? 'No messages yet.';
            final members = chatRoomData['members'] as List<dynamic>;
            final otherUserId = members.firstWhere((id) => id != _auth.currentUser!.uid);

            return _buildConversationListItem(otherUserId, lastMessage);
          },
        );
      },
    );

  // Build a single conversation list item
  Widget _buildConversationListItem(String otherUserId, String lastMessage) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(otherUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final String userName = userData['username'] ?? 'No Name';
        final String? imageUrl = userData['imageUrl'] as String?;
        final String userEmail = userData['email'] ?? 'No Email';
        final bool isOnline = userData['isOnline'] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    receiverUserEmail: userEmail,
                    receiverUserId: otherUserId,
                    receiverUserName: userName,
                    receiverImageUrl: imageUrl,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // CircleAvatar with online indicator
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFD4AF37),
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(Icons.person, color: Colors.black, size: 30)
                            : null,
                      ),
                      if (isOnline)
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessage,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Dark background color
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // User Profile Image
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final imageUrl = userData['imageUrl'] as String?;
                        return GestureDetector(
                          onTap: () {
                            if (imageUrl != null && imageUrl.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageViewScreen(imageUrl: imageUrl),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF1B1B1B),
                              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: (imageUrl == null || imageUrl.isEmpty)
                                  ? const Icon(Icons.person, color: Color(0xFFD4AF37), size: 24)
                                  : null,
                            ),
                          ),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFF1B1B1B),
                          child: Icon(Icons.person, color: Color(0xFFD4AF37), size: 24),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    'My Chats',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // The content of the selected tab
            Expanded(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFD4AF37), // لون الأيقونة المحددة
        unselectedItemColor: Colors.grey, // لون الأيقونات غير المحددة
        backgroundColor: const Color(0xFF171923),
        onTap: _onItemTapped,
      ),
    );
  }
}

// A separate class for the conversation list widget to be used in the bottom navigation bar
class _ConversationList extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getChatRooms(_auth.currentUser!.uid),
      builder: (context, chatRoomsSnapshot) {
        if (chatRoomsSnapshot.hasError) {
          return const Center(child: Text('Something went wrong.'));
        }
        if (chatRoomsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        if (!chatRoomsSnapshot.hasData || chatRoomsSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Initiate Conversation 💬',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          itemCount: chatRoomsSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chatRoomData = chatRoomsSnapshot.data!.docs[index].data() as Map<String, dynamic>;
            final lastMessage = chatRoomData['lastMessage'] ?? 'No messages yet.';
            final members = chatRoomData['members'] as List<dynamic>;
            final otherUserId = members.firstWhere((id) => id != _auth.currentUser!.uid);

            return _buildConversationListItem(context, otherUserId, lastMessage);
          },
        );
      },
    );
  }

  Widget _buildConversationListItem(BuildContext context, String otherUserId, String lastMessage) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(otherUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final String userName = userData['username'] ?? 'No Name';
        final String? imageUrl = userData['imageUrl'] as String?;
        final String userEmail = userData['email'] ?? 'No Email';
        final bool isOnline = userData['isOnline'] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    receiverUserEmail: userEmail,
                    receiverUserId: otherUserId,
                    receiverUserName: userName,
                    receiverImageUrl: imageUrl,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // CircleAvatar with online indicator
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFD4AF37),
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(Icons.person, color: Colors.black, size: 30)
                            : null,
                      ),
                      if (isOnline)
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessage,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
