import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Sigin_Screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _items = ['Item 1', 'Item 2', 'Item 3'];
  final TextEditingController _textController = TextEditingController();

  void _addItem(String item) {
    setState(() => _items.add(item));
    _textController.clear();
  }

  void _editItem(int index, String newItem) {
    setState(() => _items[index] = newItem);
    _textController.clear();
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _showFormDialog({int? index}) {
    if (index != null) {
      _textController.text = _items[index];
    } else {
      _textController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add New Item' : 'Update Item'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(hintText: 'Enter item name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                index == null ? _addItem(_textController.text) : _editItem(index, _textController.text);
                Navigator.pop(context);
              }
            },
            child: Text(index == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Static CRUD'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Asli Logout
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SiginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No data found.'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_items[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFormDialog(index: index)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(index)),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
