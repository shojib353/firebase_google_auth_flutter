import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart'; // Generated file

@HiveType(typeId: 0) // Must be unique for each model
class UserModel {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  UserModel({required this.name, required this.age});// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Optional: Create model from Firebase Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
    );
  }
}