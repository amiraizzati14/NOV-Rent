import 'package:cloud_firestore/cloud_firestore.dart';

class CarService {
  CarService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _cars =>
      _db.collection('cars');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCars() {
    // Jangan memakai orderBy di sini agar dokumen lama yang belum memiliki
    // field createdAt tetap ikut tampil.
    return _cars.snapshots();
  }

  Future<String> createCar(Map<String, dynamic> data) async {
    final reference = await _cars.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> updateCar(String id, Map<String, dynamic> data) {
    return _cars.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCar(String id) => _cars.doc(id).delete();
}
