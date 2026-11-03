// katalog_screen.dart
import 'package:flutter/material.dart';

class KatalogScreen extends StatelessWidget {
  const KatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Katalog Mobil')),
      body: const Center(child: Text('Grid/List Katalog Mobil')),
    );
  }
}