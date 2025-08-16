import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/post_model.dart';

class PostService {
  final _firestore = FirebaseFirestore.instance;
  final String _hiveBoxName = 'posts';

  Future<List<PostModel>> getPosts() async {
    final hiveBox = await Hive.openBox<PostModel>(_hiveBoxName);
    return hiveBox.values.toList();
  }

  Future<void> addPost(PostModel post) async {
    final hiveBox = await Hive.openBox<PostModel>(_hiveBoxName);
    await hiveBox.add(post);

    if (await _hasInternet()) {
      await syncUnsyncedPosts();
    }
  }

  Future<void> syncUnsyncedPosts() async {
    final hiveBox = await Hive.openBox<PostModel>(_hiveBoxName);
    final unsyncedPosts = hiveBox.values.where((p) => !p.isSynced).toList();

    for (var post in unsyncedPosts) {
      try {
        await _firestore.collection('posts').add(post.toMap());

        int index = hiveBox.values.toList().indexOf(post);
        if (index != -1) {
          final key = hiveBox.keyAt(index);
          final syncedPost = PostModel(
            title: post.title,
            content: post.content,
            createdAt: post.createdAt,
            isSynced: true,
          );
          await hiveBox.put(key, syncedPost);
        }
      } catch (e) {
        // Leave unsynced if failed
      }
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await _firestore.collection('test').limit(1).get();
      return result.docs.isNotEmpty || result.docs.isEmpty;
    } catch (_) {
      return false;
    }
  }
}
