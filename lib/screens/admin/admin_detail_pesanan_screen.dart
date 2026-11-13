
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDetailPesananScreen extends StatefulWidget {
  final String orderId;

  const AdminDetailPesananScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AdminDetailPesananScreen> createState() =>
      _AdminDetailPesananScreenState();
}

class _AdminDetailPesananScreenState
    extends State<AdminDetailPesananScreen> {
  static const blue = Color(0xFF005BCB);
  static const ink = Color(0xFF182238);
  static const muted = Color(0xFF687387);
  static const bg = Color(0xFFF7F8FD);
  static const green = Color(0xFF006747);

  bool _processing = false;

  final db = FirebaseFirestore.instance;

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _dateFormat(dynamic value) {
    final date = _date(value);
    if (date == null) return '-';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _timeFormat(dynamic value) {
    final date = _date(value);
    if (date == null) return '09:00 WIB';

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')} WIB';
  }

  String _rupiah(dynamic value) {
    final amount = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
    );

    return 'Rp$formatted';
  }

  String _value(dynamic value, [String fallback = '-']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  Future<void> _confirmOrder(
      String orderId,
      Map<String, dynamic> order,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: const Text(
          'Apakah kamu yakin ingin mengonfirmasi pesanan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
            ),
            child: const Text(
              'Konfirmasi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processing = true);

    try {
      await db.collection('orders').doc(orderId).update({
        'orderStatus': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dikonfirmasi.'),
          backgroundColor: green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengonfirmasi pesanan: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan alasan penolakan pesanan.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Tolak Pesanan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    setState(() => _processing = true);

    try {
      await db.collection('orders').doc(orderId).update({
        'orderStatus': 'rejected',
        'rejectionReason': reasonController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil ditolak.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menolak pesanan: $e')),
      );
    } finally {
      reasonController.dispose();
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showPaymentProof(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pembayaran belum tersedia.'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bukti Transfer',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('Gambar bukti transfer tidak dapat dibuka.'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value, {
        bool bold = false,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: muted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, {bool success = false}) {
    final color = success ? green : blue;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: success
            ? const Color(0xFFE5F5EF)
            : const Color(0xFFE7EEFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _documentStatus(String title, dynamic status) {
    final verified = status?.toString().toLowerCase() == 'verified';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified,
              size: 20,
              color: verified ? green : muted,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    verified ? 'Terverifikasi' : 'Belum diverifikasi',
                    style: TextStyle(
                      fontSize: 10,
                      color: verified ? green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(String? url, {double width = 112, double height = 80}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF0F2F5),
        child: url != null && url.isNotEmpty
            ? Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.directions_car,
            color: muted,
          ),
        )
            : const Icon(Icons.directions_car, color: muted),
      ),
    );
  }

  Widget _scheduleItem({
    required IconData icon,
    required Color color,
    required String title,
    required String date,
    required String time,
    required String location,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$date • $time',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _loadRelated(
      Map<String, dynamic> order,
      ) async {
    final userId = order['userId']?.toString() ?? '';
    final carId = order['carId']?.toString() ?? '';

    final results = await Future.wait([
      if (userId.isNotEmpty)
        db.collection('users').doc(userId).get()
      else
        Future.value(null),
      if (carId.isNotEmpty)
        db.collection('cars').doc(carId).get()
      else
        Future.value(null),
      db.collection('payments')
          .where('orderId', isEqualTo: widget.orderId)
          .limit(1)
          .get(),
    ]);

    final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>?;
    final carDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>?;
    final paymentQuery =
    results[2] as QuerySnapshot<Map<String, dynamic>>;

    return {
      'user': userDoc?.data() ?? <String, dynamic>{},
      'car': carDoc?.data() ?? <String, dynamic>{},
      'payment': paymentQuery.docs.isNotEmpty
          ? paymentQuery.docs.first.data()
          : <String, dynamic>{},
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFF),
        elevation: 0,
        foregroundColor: ink,
        title: const Text(
          'Booking Resolution Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: blue,
              child: Icon(Icons.person, color: Colors.white, size: 19),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: blue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat pesanan: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Data pesanan tidak ditemukan.'),
            );
          }

          final order = snapshot.data!.data() ?? {};

          return FutureBuilder<Map<String, dynamic>>(
            future: _loadRelated(order),
            builder: (context, relatedSnapshot) {
              if (relatedSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: blue),
                );
              }

              if (relatedSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Gagal memuat data terkait: ${relatedSnapshot.error}',
                  ),
                );
              }

              final related = relatedSnapshot.data ?? {};
              final user = related['user'] as Map<String, dynamic>? ?? {};
              final car = related['car'] as Map<String, dynamic>? ?? {};
              final payment =
                  related['payment'] as Map<String, dynamic>? ?? {};

              final orderNumber =
              _value(order['orderNumber'], widget.orderId);
              final carName = _value(
                order['carName'],
                _value(car['name'], 'Kendaraan'),
              );
              final carImage = _value(
                order['carImage'],
                _value(car['imageUrl'], ''),
              );

              final start = order['startDate'];
              final end = order['endDate'];

              final serviceType =
              order['serviceType']?.toString() == 'dengan_sopir'
                  ? 'Dengan Sopir'
                  : 'Lepas Kunci';

              final orderStatus =
                  order['orderStatus']?.toString() ?? 'pending';

              final paymentStatus =
                  order['paymentStatus']?.toString() ?? 'menunggu_verifikasi';

              final isConfirmed = [
                'confirmed',
                'aktif',
                'active',
                'selesai',
                'completed',
              ].contains(orderStatus.toLowerCase());

              final isRejected = [
                'rejected',
                'dibatalkan',
                'cancelled',
              ].contains(orderStatus.toLowerCase());

              final paymentProof =
              payment['proofImageUrl']?.toString();

              final userName = _value(
                order['userName'],
                _value(user['name'], 'Pelanggan'),
              );

              final userPhone = _value(
                order['userPhone'],
                _value(user['phone'], '-'),
              );

              final ktpStatus = user['verificationStatus'];
              final simStatus = user['verificationStatus'];

              final rentalDays =
                  (order['rentalDays'] as num?)?.toInt() ?? 1;

              final unitPrice =
                  (order['unitPricePerDay'] as num?)?.toInt() ?? 0;
              final deliveryFee =
                  (order['deliveryFee'] as num?)?.toInt() ?? 0;
              final driverFee =
                  (order['driverFee'] as num?)?.toInt() ?? 0;
              final insuranceFee =
                  (order['insuranceFee'] as num?)?.toInt() ?? 0;
              final deposit =
                  (order['depositAmount'] as num?)?.toInt() ??
                      (order['deposit'] as num?)?.toInt() ??
                      0;
              final total =
                  (order['grandTotal'] as num?)?.toInt() ?? 0;

              final paymentLabel = paymentStatus == 'menunggu_verifikasi'
                  ? 'Menunggu Verifikasi'
                  : paymentStatus;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  // ORDER STATUS
                  _card(
                    title: 'ID Pesanan: #$orderNumber',
                    trailing: _statusBadge(
                      isConfirmed
                          ? 'DIKONFIRMASI'
                          : isRejected
                          ? 'DITOLAK'
                          : 'PERLU KONFIRMASI',
                      success: isConfirmed,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Dipesan ${_dateFormat(order['createdAt'])}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                            const Spacer(),
                            _statusBadge(
                              isConfirmed ? 'Unit Siap Jalan' : 'Menunggu',
                              success: isConfirmed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // VEHICLE
                  _card(
                    title: 'Unit Kendaraan',
                    trailing: _statusBadge(serviceType),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _image(carImage),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                carName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _value(car['licensePlate'], 'Plat belum tersedia'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                              Text(
                                _value(car['year'], '').toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_value(car['transmission'], 'Transmisi belum tersedia')} • '
                                    '${_value(car['capacity'], 'Kapasitas belum tersedia')} Kursi',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // SCHEDULE
                  _card(
                    title: 'Jadwal & Rute Perjalanan',
                    trailing: _statusBadge('Total $rentalDays Hari'),
                    child: Column(
                      children: [
                        _scheduleItem(
                          icon: Icons.flight_takeoff,
                          color: blue,
                          title: 'Pengambilan',
                          date: _dateFormat(start),
                          time: _timeFormat(start),
                          location: _value(
                            order['pickupLocation'],
                            _value(
                              order['deliveryAddress'],
                              order['deliveryMethod'] == 'diantar'
                                  ? 'Alamat pengantaran pelanggan'
                                  : 'Lokasi pengambilan belum tersedia',
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: SizedBox(
                            height: 18,
                            child: VerticalDivider(
                              color: Color(0xFFCCD7ED),
                              thickness: 1.5,
                            ),
                          ),
                        ),
                        _scheduleItem(
                          icon: Icons.store,
                          color: green,
                          title: 'Pengembalian',
                          date: _dateFormat(end),
                          time: _timeFormat(end),
                          location: _value(
                            order['returnLocation'],
                            'Lokasi pengembalian belum tersedia',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CUSTOMER
                  _card(
                    title: 'Profil Penyewa',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: const Color(0xFFE5ECFA),
                              backgroundImage:
                              (user['photoUrl'] ?? user['profileImage'])
                                  ?.toString()
                                  .isNotEmpty ==
                                  true
                                  ? NetworkImage(
                                (user['photoUrl'] ??
                                    user['profileImage'])
                                    .toString(),
                              )
                                  : null,
                              child: const Icon(
                                Icons.person,
                                color: blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    userPhone,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _documentStatus('e-KTP', ktpStatus),
                            const SizedBox(width: 8),
                            _documentStatus('SIM A', simStatus),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: userPhone == '-'
                                    ? null
                                    : () {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Hubungi pelanggan melalui nomor yang tercantum.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_outlined),
                                label: const Text('WhatsApp'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: green,
                                  side: const BorderSide(color: green),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.phone_outlined),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFE9EEFF),
                                foregroundColor: blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // PAYMENT
                  _card(
                    title: 'Rincian Pembayaran',
                    trailing: _statusBadge(paymentLabel),
                    child: Column(
                      children: [
                        _infoRow(
                          'Sewa Unit ($rentalDays Hari)',
                          _rupiah(unitPrice * rentalDays),
                        ),
                        if (deliveryFee > 0)
                          _infoRow(
                            'Biaya Antar',
                            _rupiah(deliveryFee),
                          ),
                        if (driverFee > 0)
                          _infoRow(
                            'Biaya Sopir',
                            _rupiah(driverFee),
                          ),
                        if (insuranceFee > 0)
                          _infoRow(
                            'Biaya Asuransi',
                            _rupiah(insuranceFee),
                          ),
                        if (deposit > 0)
                          _infoRow(
                            'Deposit Jaminan (Refundable)',
                            _rupiah(deposit),
                          ),
                        const Divider(height: 22),
                        _infoRow(
                          'Total Tagihan',
                          _rupiah(total),
                          bold: true,
                          color: blue,
                        ),
                        _infoRow(
                          'Metode Pembayaran',
                          _value(order['paymentMethod']),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _showPaymentProof(paymentProof),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F3FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  color: blue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Bukti Transfer',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        paymentProof != null &&
                                            paymentProof.isNotEmpty
                                            ? 'Bukti transfer telah diunggah'
                                            : 'Belum ada bukti transfer',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!isConfirmed && !isRejected) ...[
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _processing
                            ? null
                            : () => _confirmOrder(widget.orderId, order),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        label: Text(
                          _processing
                              ? 'Memproses...'
                              : 'Konfirmasi Pesanan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2164E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showPaymentProof(paymentProof),
                            icon: const Icon(Icons.account_balance_wallet_outlined),
                            label: const Text('Cek Pembayaran'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: blue,
                              backgroundColor: const Color(0xFFE9EEFF),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _processing
                                ? null
                                : () => _rejectOrder(widget.orderId),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Tolak Pesanan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              backgroundColor: const Color(0xFFFFF0F0),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    _statusBadge(
                      isConfirmed
                          ? 'Pesanan telah dikonfirmasi'
                          : 'Pesanan telah ditolak',
                      success: isConfirmed,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
