import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_shered_pref/post_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_shered_pref/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = '';
  String email = '';
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  late Box<UserModel> userBox;

  Future<void> _loadUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      name = user?.displayName ?? prefs.getString('name') ?? 'User';
      email = user?.email ?? prefs.getString('email') ?? 'No Email';
    });

    userBox = Hive.box<UserModel>('UserDataBox');
  }

  Future<void> _saveUserProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and age')),
      );
      return;
    }

    final person = UserModel(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
    );

    await userBox.add(person); // Store new entry in Hive
    _nameController.clear();
    _ageController.clear();
    addFirebaseUser(person); // Add to Firestore

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostPage()),
    );
  }

  Future<void> _deleteUser(int index) async {
    await userBox.deleteAt(index);
    // deleteFirebaseUser();
  }

//firebase firestore
  Future<void> addFirebaseUser(UserModel user) async {
    await FirebaseFirestore.instance.collection('users').add(user.toMap());
  }

  Future<void> deleteFirebaseUser(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .delete();
  }



  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        toolbarHeight: 70,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $name!', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),

            // Name Input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter your name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Age Input
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter your age',
                prefixIcon: const Icon(Icons.cake),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveUserProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Person'),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Hive Stored Data:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Live Hive Data List
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<UserModel>('UserDataBox').listenable(),
                builder: (context, Box<UserModel> box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text('No data in Hive'));
                  }
                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final user = box.getAt(index);
                      return Card(
                        child: ListTile(
                          title: Text(user?.name ?? 'No Name'),
                          subtitle: Text('Age: ${user?.age ?? 0}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(index),
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
