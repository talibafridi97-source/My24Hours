import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'user': 'Zain Ahmed',
      'content': 'Just launched my new Flutter app! 🚀 The UI looks amazing.',
      'time': '2 mins ago',
      'likes': 12,
      'color': Colors.orangeAccent
    },
    {
      'user': 'Sara Khan',
      'content': 'Modern UI design is all about gradients and spacing. #FlutterDev',
      'time': '1 hour ago',
      'likes': 45,
      'color': Colors.pinkAccent
    },
  ];

  final _postController = TextEditingController();

  void _addPost() {
    if (_postController.text.isNotEmpty) {
      setState(() {
        _posts.insert(0, {
          'user': FirebaseAuth.instance.currentUser?.displayName ?? 'Me',
          'content': _postController.text,
          'time': 'Just now',
          'likes': 0,
          'color': Colors.deepPurpleAccent
        });
      });
      _postController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Create a New Post', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _postController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _addPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('POST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Social Feed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 5,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: post['color'],
                        child: Text(post['user'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['user'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(post['time'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    post['content'],
                    style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 5),
                          Text('${post['likes']} likes', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: const Text('Comment'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostModal,
        backgroundColor: const Color(0xFF2575FC),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
