import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_shered_pref/services/post_service.dart';
import 'models/post_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final postService = PostService();
  List<PostModel> posts = [];
  late final Connectivity _connectivity;
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();

    // Listen for internet changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
          if (result != ConnectivityResult.none) {
            postService.syncUnsyncedPosts();
          }
        });

    loadPosts();
  }

  Future<void> loadPosts() async {
    final data = await postService.getPosts();
    setState(() {
      posts = data;
    });
  }

  void _addPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: "Content")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                final post = PostModel(
                  title: titleController.text,
                  content: contentController.text,
                  createdAt: DateTime.now(),
                  isSynced: false, // offline state
                );

                setState(() {
                  posts.add(post); // ✅ show instantly
                });

                Navigator.pop(context);

                // Save to local DB (Hive) — Firestore sync will happen later
                postService.addPost(post).then((_) => loadPosts());
              }
            }
            ,
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline Firestore Sync")),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (_, i) {
          final post = posts[i];
          return ListTile(
            title: Text(post.title),
            subtitle: Text(post.content),
            trailing: Icon(
              post.isSynced ? Icons.cloud_done : Icons.cloud_off,
              color: post.isSynced ? Colors.green : Colors.red,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}