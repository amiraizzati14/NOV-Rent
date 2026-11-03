import 'package:flutter/material.dart';

class PesananScreen extends StatelessWidget {
  const PesananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Mobil')),
      body: const Center(child: Text('Grid/List Pesanan Mobil')),
    );
  }
}
