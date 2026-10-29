import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOV Rent', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2B5CFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Diskon 20% untuk Penyewaan Pertama!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          const Text('Mobil Populer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Tesla Model 3'),
            subtitle: const Text('Electric • Rp 1.5M / hari'),
            trailing: const Icon(Icons.chevron_right),
            tileColor: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => context.push('/detail/1'),
          )
        ],
      ),
    );
  }
}