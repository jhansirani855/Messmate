import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> allPosts = []; // all fetched posts
  List<DocumentSnapshot> posts = [];    // currently displayed posts
  String searchQuery = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  /// Logout
  void logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  /// Reaction system
  Future<void> reactToItem(String itemId, String reactionType) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final docRef = _firestore.collection('items').doc(itemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      Map<String, dynamic> reactions =
          Map<String, dynamic>.from(data['reactions'] ?? {});
      int likes = data['likes'] ?? 0;
      int dislikes = data['dislikes'] ?? 0;
      int moderates = data['moderates'] ?? 0;

      String? prevReaction = reactions[userId];

      if (prevReaction == 'like') likes--;
      if (prevReaction == 'dislike') dislikes--;
      if (prevReaction == 'moderate') moderates--;

      if (prevReaction == reactionType) {
        reactions.remove(userId);
      } else {
        reactions[userId] = reactionType;
        if (reactionType == 'like') likes++;
        if (reactionType == 'dislike') dislikes++;
        if (reactionType == 'moderate') moderates++;
      }

      transaction.update(docRef, {
        'likes': likes,
        'dislikes': dislikes,
        'moderates': moderates,
        'reactions': reactions,
      });
    });
  }

  /// Add comment
  Future<void> addComment(String itemId, String comment) async {
    if (comment.trim().isEmpty) return;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('items')
        .doc(itemId)
        .collection('comments')
        .add({
      'userId': userId,
      'comment': comment.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch all posts
  Future<void> fetchPosts() async {
    setState(() => isLoading = true);

    QuerySnapshot snapshot = await _firestore
        .collection('items')
        .orderBy('timestamp', descending: true)
        .get();

    allPosts = snapshot.docs;
    applySearchFilter();

    setState(() => isLoading = false);
  }

  /// Apply search locally
  void applySearchFilter() {
    if (searchQuery.isEmpty) {
      setState(() => posts = List.from(allPosts));
      return;
    }

    final filteredPosts = allPosts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      return title.contains(searchQuery);
    }).toList();

    setState(() => posts = filteredPosts);
  }

  void onSearchChanged(String query) {
    searchQuery = query.trim().toLowerCase();
    applySearchFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Dashboard"),
        backgroundColor: Colors.purple,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: logout)],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchChanged,
            ),
          ),

          // Post feed
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final data = posts[index].data() as Map<String, dynamic>;
                      final itemId = posts[index].id;
                      final commentController = TextEditingController();

                      Map<String, dynamic> reactions =
                          Map<String, dynamic>.from(data['reactions'] ?? {});
                      String? myReaction = reactions[_auth.currentUser?.uid ?? ''];

                      return Card(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.purple),
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 6),
                              Text(data['description'] ?? ''),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.thumb_up,
                                        color: myReaction == 'like'
                                            ? Colors.green
                                            : Colors.grey),
                                    onPressed: () => reactToItem(itemId, 'like'),
                                  ),
                                  Text("${data['likes'] ?? 0}"),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: Icon(Icons.thumb_down,
                                        color: myReaction == 'dislike'
                                            ? Colors.red
                                            : Colors.grey),
                                    onPressed: () => reactToItem(itemId, 'dislike'),
                                  ),
                                  Text("${data['dislikes'] ?? 0}"),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: Icon(Icons.sentiment_neutral,
                                        color: myReaction == 'moderate'
                                            ? Colors.orange
                                            : Colors.grey),
                                    onPressed: () =>
                                        reactToItem(itemId, 'moderate'),
                                  ),
                                  Text("${data['moderates'] ?? 0}"),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: commentController,
                                decoration: const InputDecoration(
                                  labelText: "Comment",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple),
                                  onPressed: () async {
                                    await addComment(itemId, commentController.text);
                                    commentController.clear();
                                  },
                                  child: const Text("Submit"),
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                      final d = c.data() as Map<String, dynamic>;
                                      return Text(
                                          "${d['userId'] ?? 'Anonymous'}: ${d['comment']}");
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
