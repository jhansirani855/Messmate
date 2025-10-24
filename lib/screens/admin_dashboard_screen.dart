import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> addItem() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) return;

    final itemRef = await _firestore.collection('items').add({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'dislikes': 0,
      'moderates': 0,
      'reactions': {}, // userId: reaction
    });

    // Initialize empty comments subcollection
    await itemRef.collection('comments').doc('init').set({'init': true});
    await itemRef.collection('comments').doc('init').delete();

    _titleController.clear();
    _descController.clear();
  }

  Future<void> deleteItem(String itemId) async {
    final itemRef = _firestore.collection('items').doc(itemId);

    // Delete all comments first
    final comments = await itemRef.collection('comments').get();
    for (var c in comments.docs) {
      await c.reference.delete();
    }

    // Delete the item itself
    await itemRef.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.purple,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: logout)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: addItem,
              child: const Text("Add Item"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('items')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final items = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final itemData = items[index].data() as Map<String, dynamic>;
                      final itemId = items[index].id;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(itemData['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(itemData['description'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                  "Likes: ${itemData['likes'] ?? 0}, Dislikes: ${itemData['dislikes'] ?? 0}, Moderate: ${itemData['moderates'] ?? 0}"),
                              const SizedBox(height: 8),

                              // 🔹 Live comments subcollection
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('items')
                                    .doc(itemId)
                                    .collection('comments')
                                    .orderBy('timestamp', descending: false)
                                    .snapshots(),
                                builder: (context, commentSnapshot) {
                                  if (!commentSnapshot.hasData) return const SizedBox();
                                  final comments = commentSnapshot.data!.docs;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: comments.map((c) {
                                      final data = c.data() as Map<String, dynamic>;
                                      if (data.containsKey('init')) return const SizedBox();
                                      return Text(
                                          "${data['userId'] ?? 'Anonymous'}: ${data['comment']}");
                                    }).toList(),
                                  );
                                },
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteItem(itemId),
                                ),
                              ),
                            ],
                          ),
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