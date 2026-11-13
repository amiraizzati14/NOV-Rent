import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_constants.dart';
import 'status_pembayaran_screen.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper status badge color & text
  Map<String, dynamic> _getStatusConfig(String? status) {
    final s = status?.toLowerCase() ?? 'menunggu_verifikasi';
    switch (s) {
      case 'menunggu_pembayaran':
      case 'pending_payment':
        return {
          'text': 'Belum Bayar',
          'bg': AppColors.warningLight,
          'color': AppColors.warning,
          'icon': Icons.hourglass_top_rounded,
        };
      case 'menunggu_verifikasi':
      case 'pending_verification':
      case 'pending':
        return {
          'text': 'Menunggu Verifikasi',
          'bg': const Color(0xFFFFF7E6),
          'color': const Color(0xFFD46B08),
          'icon': Icons.hourglass_bottom_rounded,
        };
      case 'confirmed':
      case 'lunas':
        return {
          'text': 'Dikonfirmasi',
          'bg': AppColors.successLight,
          'color': AppColors.success,
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'aktif':
      case 'active':
        return {
          'text': 'Sedang Berjalan',
          'bg': AppColors.primaryLight,
          'color': AppColors.primary,
          'icon': Icons.directions_car_filled_rounded,
        };
      case 'selesai':
      case 'completed':
        return {
          'text': 'Selesai',
          'bg': const Color(0xFFF0F2F5),
          'color': AppColors.textSubtitle,
          'icon': Icons.task_alt_rounded,
        };
      case 'dibatalkan':
      case 'cancelled':
      case 'rejected':
        return {
          'text': 'Dibatalkan',
          'bg': AppColors.dangerLight,
          'color': AppColors.danger,
          'icon': Icons.cancel_outlined,
        };
      default:
        return {
          'text': 'Diproses',
          'bg': AppColors.primaryLight,
          'color': AppColors.primary,
          'icon': Icons.info_outline_rounded,
        };
    }
  }

  bool _filterByTab(String? status, int tabIndex) {
    final s = status?.toLowerCase() ?? '';
    switch (tabIndex) {
      case 0: // Semua
        return true;
      case 1: // Menunggu
        return s == 'menunggu_pembayaran' ||
            s == 'pending_payment' ||
            s == 'menunggu_verifikasi' ||
            s == 'pending_verification' ||
            s == 'pending';
      case 2: // Aktif / Dikonfirmasi
        return s == 'confirmed' || s == 'lunas' || s == 'aktif' || s == 'active';
      case 3: // Selesai / Batal
        return s == 'selesai' || s == 'completed' || s == 'dibatalkan' || s == 'cancelled' || s == 'rejected';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Pesanan Saya',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Silakan login untuk melihat pesanan',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Login Sekarang'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Menunggu'),
                Tab(text: 'Aktif'),
                Tab(text: 'Riwayat Selesai'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan memuat data pesanan:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Urutkan in-memory dari yang paling baru ke lama
          final sortedDocs = [...allDocs]..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp? ?? Timestamp.now();
              final bTime = b.data()['createdAt'] as Timestamp? ?? Timestamp.now();
              return bTime.compareTo(aTime);
            });

          return TabBarView(
            controller: _tabController,
            children: List.generate(4, (tabIndex) {
              final filteredDocs = sortedDocs.where((doc) {
                final status = doc.data()['paymentStatus']?.toString() ?? doc.data()['orderStatus']?.toString();
                return _filterByTab(status, tabIndex);
              }).toList();

              if (filteredDocs.isEmpty) {
                return _buildEmptyState(tabIndex);
              }

              return RefreshIndicator(
                onRefresh: () async {},
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final orderDoc = filteredDocs[index];
                    return _buildOrderCard(orderDoc);
                  },
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String message = 'Kamu belum memiliki pesanan aktif.';
    if (tabIndex == 1) message = 'Tidak ada pesanan yang sedang menunggu verifikasi.';
    if (tabIndex == 2) message = 'Tidak ada pesanan mobil yang sedang berjalan.';
    if (tabIndex == 3) message = 'Belum ada riwayat pesanan yang selesai.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.directions_car_outlined, size: 18),
              label: const Text('Cari Mobil Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final orderId = doc.id;

    final orderNumber = data['orderNumber']?.toString() ?? '#NOV-${orderId.substring(0, 8).toUpperCase()}';
    final carName = data['carName']?.toString() ?? 'Mobil';
    final carImage = data['carImage']?.toString() ?? '';
    final grandTotal = data['grandTotal'] as num? ?? 0;
    final rentalDays = data['rentalDays'] as int? ?? 1;

    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    final serviceType = data['serviceType']?.toString() == 'dengan_sopir' ? 'Dengan Sopir' : 'Lepas Kunci';
    final deliveryMethod = data['deliveryMethod']?.toString() == 'diantar' ? 'Diantar' : 'Ambil di Pool';

    final paymentStatus = data['paymentStatus']?.toString() ?? data['orderStatus']?.toString();
    final statusConfig = _getStatusConfig(paymentStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nomor Order & Status Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderNumber.startsWith('#') ? orderNumber : '#$orderNumber',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Dibuat: ${AppFormatters.dateWithYear(createdAt)} • ${AppFormatters.timeWib(createdAt)}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusConfig['bg'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusConfig['icon'] as IconData, size: 12, color: statusConfig['color'] as Color),
                      const SizedBox(width: 4),
                      Text(
                        statusConfig['text'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusConfig['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.cardBorder),

          // Content: Foto Mobil & Info Sewa
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 78,
                    height: 58,
                    color: const Color(0xFFF2F4F7),
                    child: carImage.isNotEmpty
                        ? Image.network(
                            carImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.directions_car,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(Icons.directions_car, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(serviceType, AppColors.primaryLight, AppColors.primary),
                          _chip(deliveryMethod, const Color(0xFFF0F2F5), AppColors.textSubtitle),
                        ],
                      ),
                      const SizedBox(height: 7),
                      if (startDate != null && endDate != null)
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${AppFormatters.dateShort(startDate)} – ${AppFormatters.dateShort(endDate)} ($rentalDays Hari)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSubtitle,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.cardBorder),

          // Footer: Total Biaya & Tombol Aksi
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.rupiah(grandTotal),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StatusPembayaranScreen(
                          bookingCode: orderNumber,
                          carName: carName,
                          carCategory: data['carCategory']?.toString() ?? 'Mobil',
                          carYear: data['carYear']?.toString() ?? '-',
                          transmission: data['transmission']?.toString() ?? 'Automatic',
                          carImage: carImage,
                          startDate: startDate != null
                              ? AppFormatters.dateWithYear(startDate)
                              : '-',
                          endDate: endDate != null
                              ? AppFormatters.dateWithYear(endDate)
                              : '-',
                          duration: '$rentalDays Hari',
                          rentalType: serviceType,
                          totalPayment: AppFormatters.rupiah(grandTotal),
                          proofFileName: data['proofFileName']?.toString() ?? 'Bukti transfer',
                          proofFileSize: data['proofFileSize']?.toString() ?? 'File terunggah',
                          senderName: data['senderName']?.toString() ?? '-',
                          senderBank: data['senderBank']?.toString() ?? '-',
                          transferTime: '-',
                          proofImageUrl: data['paymentProofUrl']?.toString() ?? '',
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(0, 34),
                  ),
                  child: const Text(
                    'Detail Pesanan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
