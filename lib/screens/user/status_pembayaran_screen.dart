
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusPembayaranScreen extends StatelessWidget {
  final String bookingCode;
  final String carName;
  final String carCategory;
  final String carYear;
  final String transmission;
  final String carImage;
  final String startDate;
  final String endDate;
  final String duration;
  final String rentalType;
  final String totalPayment;
  final String proofFileName;
  final String proofFileSize;
  final String senderName;
  final String senderBank;
  final String transferTime;
  final String? proofImageUrl;
  final VoidCallback? onViewOrder;
  final VoidCallback? onHome;

  const StatusPembayaranScreen({
    super.key,
    required this.bookingCode,
    required this.carName,
    required this.carCategory,
    required this.carYear,
    required this.transmission,
    required this.carImage,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.rentalType,
    required this.totalPayment,
    required this.proofFileName,
    required this.proofFileSize,
    required this.senderName,
    required this.senderBank,
    required this.transferTime,
    this.proofImageUrl,
    this.onViewOrder,
    this.onHome,
  });

  static const Color blue = Color(0xFF005BCB);
  static const Color background = Color(0xFFF9F8FE);
  static const Color orange = Color(0xFFD46B08);
  static const Color ink = Color(0xFF202126);
  static const Color muted = Color(0xFF74798D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Status Pembayaran',
          style: TextStyle(
            color: ink,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: blue,
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          children: [
            // STATUS UTAMA
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDCC8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFFB95B00),
                size: 43,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Menunggu Persetujuan Admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE9EF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 14, color: orange),
                  SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Estimasi verifikasi 10 – 30 menit (07:00 – 22:00 WIB)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF474D5E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TAHAPAN PEMERIKSAAN
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Tahapan Pemeriksaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '3 Dokumen',
                        style: TextStyle(
                          fontSize: 11,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),

                  _documentItem(
                    Icons.receipt_long_outlined,
                    'Bukti Transfer',
                    'Nominal $totalPayment',
                    true,
                  ),
                  const SizedBox(height: 8),

                  _documentItem(
                    Icons.badge_outlined,
                    'KTP Elektronik',
                    'Terunggah sebelumnya',
                    false,
                  ),
                  const SizedBox(height: 8),

                  _documentItem(
                    Icons.directions_car_outlined,
                    'SIM A Aktif',
                    'Terunggah sebelumnya',
                    false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DETAIL PESANAN
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kode Booking',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bookingCode,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: bookingCode),
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kode booking berhasil disalin'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy, size: 15),
                          label: const Text('Salin'),
                          style: TextButton.styleFrom(
                            foregroundColor: ink,
                            backgroundColor: const Color(0xFFEAEAF0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          width: 80,
                          height: 65,
                          child: _carImage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carCategory.toUpperCase(),
                              style: const TextStyle(
                                color: blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              carName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tahun $carYear • $transmission',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _infoRow('Periode Sewa', '$startDate – $endDate'),
                  const SizedBox(height: 9),
                  _infoRow('Durasi', '$duration ($rentalType)'),

                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        totalPayment,
                        style: const TextStyle(
                          color: blue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Menunggu Konfirmasi',
                      style: TextStyle(
                        color: orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // RINCIAN BUKTI TRANSFER
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Rincian Bukti Terkirim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.check_circle_outline,
                        color: blue,
                        size: 21,
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 19,
                          backgroundColor: Color(0xFFE2E2E8),
                          child: Icon(
                            Icons.image_outlined,
                            color: muted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proofFileName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$proofFileSize • JPG Format',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _infoRow('Pengirim', '$senderName ($senderBank)'),
                  const SizedBox(height: 9),
                  _infoRow('Waktu Kirim', transferTime),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 47,
                    child: ElevatedButton.icon(
                      onPressed: () => _showProof(context),
                      icon: const Icon(Icons.visibility_outlined, size: 19),
                      label: const Text('Lihat Bukti Transfer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDCE5FF),
                        foregroundColor: blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // INFORMASI
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEFF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: blue,
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pesanan akan otomatis dikonfirmasi setelah data dan pembayaran disetujui admin. Notifikasi hasil verifikasi akan dikirimkan langsung ke ponsel Anda.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // BUTTON LIHAT PESANAN
            SizedBox(
              width: double.infinity,
              height: 51,
              child: ElevatedButton(
                onPressed: onViewOrder ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Lihat Pesanan  →',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            TextButton(
              onPressed: onHome ?? () => Navigator.pop(context),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carImage() {
    if (carImage.isEmpty) {
      return Container(
        color: const Color(0xFFE7EAF0),
        child: const Icon(Icons.directions_car, color: muted, size: 35),
      );
    }

    return Image.network(
      carImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFE7EAF0),
        child: const Icon(Icons.directions_car, color: muted, size: 35),
      ),
    );
  }

  Widget _documentItem(
      IconData icon,
      String title,
      String subtitle,
      bool isTransfer,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: isTransfer
                ? const Color(0xFFDCE5FF)
                : const Color(0xFFE0E4EC),
            child: Icon(
              icon,
              size: 17,
              color: isTransfer ? blue : const Color(0xFF667184),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDCC8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 7, color: orange),
                SizedBox(width: 4),
                Text(
                  'Pemeriksaan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF63320E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: muted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D1330),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  void _showProof(BuildContext context) {
    if (proofImageUrl == null || proofImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti transfer belum tersedia.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Image.network(
                proofImageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(25),
                  child: Text('Gagal memuat bukti transfer.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
