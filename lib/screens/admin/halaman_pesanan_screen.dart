import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// import 'package:go_router/go_router.dart'; // Gunakan ini untuk navigasi GoRouter

class HalamanPesanan extends StatelessWidget {
  const HalamanPesanan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Pesanan"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // orderBy dihapus sementara untuk memastikan semua data tampil,
        // meskipun ada dokumen lama yang belum punya field createdAt
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          // 1. Cek error (Sangat penting agar masalah database terlihat di layar)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Terjadi kesalahan:\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 2. Tampilkan loading HANYA saat menunggu koneksi Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memuat data pesanan..."),
                ],
              ),
            );
          }

          // 3. Cek jika data berhasil ditarik, tapi koleksi kosong
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada data pesanan masuk.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // 4. Jika data aman, render ke layar
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var document = snapshot.data!.docs[index];
              var orderData = document.data() as Map<String, dynamic>;

              // Mengambil data sesuai skema
              String orderNumber = orderData['orderNumber'] ?? '-';
              String carName = orderData['carName'] ?? 'Mobil Tidak Diketahui';
              String renterName = orderData['renterName'] ?? orderData['userName'] ?? 'Tanpa Nama';
              String paymentStatus = orderData['paymentStatus'] ?? 'menunggu_pembayaran';
              int grandTotal = orderData['grandTotal'] ?? 0;

              // Format Rupiah
              String formattedTotal = NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(grandTotal);

              // Menentukan warna badge
              Color statusColor = paymentStatus == 'lunas'
                  ? Colors.green
                  : (paymentStatus == 'dibatalkan' ? Colors.red : Colors.orange);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    carName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("ID: $orderNumber"),
                      Text("Penyewa: $renterName"),
                      const SizedBox(height: 8),
                      // Badge Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    formattedTotal,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onTap: () {
                    // Navigasi ke admin_detail_pesanan_screen.dart
                    // Implementasi menggunakan GoRouter untuk meneruskan ID unik pesanan:

                    // context.push('/admin/detail-pesanan/${document.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}