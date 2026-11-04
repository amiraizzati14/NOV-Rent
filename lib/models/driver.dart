import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;
  final String name;
  final String phone;
  final String photoUrl;
  final String gender;
  final bool isAvailable;
  final DateTime? createdAt;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl = '',
    this.gender = 'Laki-laki',
    this.isAvailable = true,
    this.createdAt,
  });

  factory Driver.fromFirestore(String id, Map<String, dynamic> data) {
    return Driver(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      gender: data['gender'] ?? 'Laki-laki',
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'gender': gender,
      'isAvailable': isAvailable,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
