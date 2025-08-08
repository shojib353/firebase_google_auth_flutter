import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = '';
  String email = '';
  final TextEditingController _ageController = TextEditingController();
  Map<dynamic, dynamic> hiveData = {};


  Future<void> _loadUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // name = prefs.getString('name') ?? '';
      // email = prefs.getString('email') ?? '';
      name=user?.displayName?? 'name';
      email=user?.email?? 'name';

    });

    var box = Hive.box('userBox');
    _ageController.text = box.get('age', defaultValue: '').toString();
    setState(() {
      hiveData = box.toMap();
    });
  }

  Future<void> _saveAge() async {
    var age = _ageController.text.trim();
    if (age.isNotEmpty) {
      var box = Hive.box('userBox');
      await box.put('age', age);
      setState(() {
        hiveData = box.toMap(); // refresh UI
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age saved to Hive')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }




  @override
  Widget build(BuildContext context) {


    // final User? user = FirebaseAuth.instance.currentUser;
    //
    // return Scaffold(
    //     appBar: AppBar(
    //       backgroundColor: Colors.deepPurple,
    //       elevation: 6,
    //       toolbarHeight: 70,
    //       shape: const RoundedRectangleBorder(
    //         borderRadius: BorderRadius.vertical(
    //           bottom: Radius.circular(20),
    //         ),
    //       ),
    //       title: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           const Text(
    //             'Welcome!',
    //             style: TextStyle(
    //               fontSize: 16,
    //               color: Colors.white70,
    //             ),
    //           ),
    //           Text(
    //             user?.displayName ?? user?.email ?? 'User',
    //             style: const TextStyle(
    //               fontSize: 20,
    //               fontWeight: FontWeight.bold,
    //               color: Colors.white,
    //               fontFamily: 'Poppins',
    //             ),
    //           ),
    //         ],
    //       ),
    //       actions: [
    //         IconButton(
    //           icon: const Icon(Icons.logout, color: Colors.white),
    //           tooltip: 'Logout',
    //           onPressed: () async {
    //             await FirebaseAuth.instance.signOut();
    //             // Navigates automatically using StreamBuilder in main.dart
    //           },
    //         ),
    //       ],
    //     ),

    return Scaffold(
      appBar:AppBar(
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
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            Text(
              name ?? email ?? 'User',
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
              // Redirect handled by authStateChanges in main.dart
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $name!', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text('Email: $email', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 32),

              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Enter your age',
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAge,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Age'),
              ),

              const SizedBox(height: 30),
              const Text(
                'Hive Stored Data:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hiveData.length,
                itemBuilder: (context, index) {
                  final key = hiveData.keys.elementAt(index);
                  final value = hiveData[key];
                  return Card(
                    child: ListTile(
                      title: Text('$key'),
                      subtitle: Text('$value'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
