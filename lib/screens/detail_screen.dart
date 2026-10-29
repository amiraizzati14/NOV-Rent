import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rental_provider.dart';

class DetailScreen extends StatelessWidget {
  final String carId;
  const DetailScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Mobil $carId')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(Icons.directions_car, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text('Spesifikasi Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5CFF)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mobil ditambahkan ke pesanan!'))
                  );
                },
                child: const Text('Sewa Sekarang', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}