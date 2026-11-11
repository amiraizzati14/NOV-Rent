import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_constants.dart';

class RingkasanPesananScreen extends StatefulWidget {
  final String carId;
  final bool withDriver;
  final DateTime? startDate;
  final DateTime? endDate;

  const RingkasanPesananScreen({
    super.key,
    required this.carId,
    this.withDriver = false,
    this.startDate,
    this.endDate,
  });

  @override
  State<RingkasanPesananScreen> createState() => _RingkasanPesananScreenState();
}

class _RingkasanPesananScreenState extends State<RingkasanPesananScreen> {
  static const Color primaryBlue = AppColors.primary;
  static const Color darkText = AppColors.textDark;
  static const Color mutedText = AppColors.textMuted;
  static const Color lightBg = AppColors.background;

  bool _isDelivery = false; // false = Ambil Sendiri, true = Diantar ke Alamat
  String _paymentMethod = 'BCA Virtual Account';
  String _paymentBank = 'BCA';

  late DateTime _start;
  late DateTime _end;
  int _rentalDays = 2;

  final int _insuranceFee = 10000;
  final int _deliveryPricePerDay = 50000;
  final int _driverPricePerDay = 150000;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start =
        widget.startDate ?? DateTime(now.year, now.month, now.day + 1, 9, 0);
    _end = widget.endDate ?? _start.add(const Duration(days: 2));

    final diff = _end.difference(_start).inDays;
    _rentalDays = diff > 0 ? diff : 2;
  }

  String _formatCurrency(num value) => AppFormatters.rupiah(value);
  String _formatDateShort(DateTime date) => AppFormatters.dateShort(date);
  String _getInitials(String name) => AppFormatters.initials(name);

  void _showPaymentPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final methods = [
          {'bank': 'BCA', 'name': 'BCA Virtual Account'},
          {'bank': 'BRI', 'name': 'BRI Virtual Account'},
          {'bank': 'Mandiri', 'name': 'Mandiri Virtual Account'},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Metode Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...methods.map((m) {
                  final isSel = _paymentMethod == m['name'];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m['bank']!,
                        style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      m['name']!,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    trailing: isSel
                        ? const Icon(Icons.check_circle, color: primaryBlue)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                    onTap: () {
                      setState(() {
                        _paymentBank = m['bank']!;
                        _paymentMethod = m['name']!;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePayment(Map<String, dynamic> car, Map<String, dynamic> user) {
    final pricePerDay = (car['pricePerDay'] as num?)?.toInt() ?? 350000;
    final unitTotal = pricePerDay * _rentalDays;
    final deliveryFee = _isDelivery ? _deliveryPricePerDay * _rentalDays : 0;
    final driverFee = widget.withDriver ? _driverPricePerDay * _rentalDays : 0;
    final grandTotal = unitTotal + _insuranceFee + deliveryFee + driverFee;

    final bookingData = <String, dynamic>{
      'carId': widget.carId,
      'carName': car['name'] ?? 'Toyota Avanza 1.3 G',
      'year': car['year']?.toString() ?? '2023',
      'carImage': car['imageUrl'] ??
          (car['imageUrls'] is List && (car['imageUrls'] as List).isNotEmpty
              ? car['imageUrls'][0]
              : ''),
      'transmission': car['transmission']?.toString() ?? 'Matic (A/T)',
      'capacity': (car['capacity'] as num?)?.toInt() ?? 7,
      'fuelType': car['fuelType']?.toString() ?? 'Bensin',
      'pricePerDay': pricePerDay,
      'startDate': _start,
      'endDate': _end,
      'rentalDays': _rentalDays,
      'withDriver': widget.withDriver,
      'isDelivery': _isDelivery,
      'deliveryAddress': _isDelivery ? 'Alamat Pengantaran Customer' : null,
      'deliveryFee': deliveryFee,
      'driverFee': driverFee,
      'insuranceFee': _insuranceFee,
      'grandTotal': grandTotal,
      'paymentBank': _paymentBank,
      'paymentMethod': _paymentMethod,
      'userName': user['name'] ?? 'Customer',
      'userPhone': user['phone'] ?? '-',
    };

    context.push('/konfirmasi-pembayaran', extra: bookingData);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ringkasan & Pembayaran')),
        body: const Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('general')
          .snapshots(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data?.data() ?? {};
        final String poolAddress = settings['poolAddress']?.toString() ??
            'Jl. Raya Bogor No. 123, Kel. Cisalak, Kec. Sukmajaya, Kota Depok';
        final Map<String, dynamic>? poolLatLng =
            settings['poolLatLng'] as Map<String, dynamic>?;
        final double poolLat =
            (poolLatLng?['lat'] as num?)?.toDouble() ?? -6.3923;
        final double poolLng =
            (poolLatLng?['lng'] as num?)?.toDouble() ?? 106.8317;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('cars')
              .doc(widget.carId)
              .snapshots(),
          builder: (context, carSnapshot) {
            if (carSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: lightBg,
                body: Center(
                    child: CircularProgressIndicator(color: primaryBlue)),
              );
            }

            if (!carSnapshot.hasData || !carSnapshot.data!.exists) {
              return Scaffold(
                appBar: AppBar(title: const Text('Ringkasan & Pembayaran')),
                body: const Center(child: Text('Data mobil tidak ditemukan.')),
              );
            }

            final car = carSnapshot.data!.data()!;

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                final user = userSnapshot.data?.data() ?? {};

                final String carName = car['name']?.toString() ?? 'Mobil';
                final String year = car['year']?.toString() ?? '2023';
                final String transmission =
                    car['transmission']?.toString() ?? 'Manual';
                final int capacity = (car['capacity'] as num?)?.toInt() ?? 7;
                final int pricePerDay =
                    (car['pricePerDay'] as num?)?.toInt() ?? 350000;
                final String imageUrl = car['imageUrl']?.toString() ??
                    (car['imageUrls'] is List &&
                            (car['imageUrls'] as List).isNotEmpty
                        ? (car['imageUrls'] as List).first.toString()
                        : '');

                final String userName = user['name']?.toString() ?? 'Pengguna';
                final String userPhone =
                    user['phone']?.toString() ?? '+62 812-3456-7890';

                // Hitung kalkulasi harga
                final int unitTotal = pricePerDay * _rentalDays;
                final int deliveryFee =
                    _isDelivery ? _deliveryPricePerDay * _rentalDays : 0;
                final int driverFee =
                    widget.withDriver ? _driverPricePerDay * _rentalDays : 0;
                final int grandTotal =
                    unitTotal + _insuranceFee + deliveryFee + driverFee;

                return Scaffold(
                  backgroundColor: lightBg,
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 20, color: darkText),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: const Text(
                      'Ringkasan & Pembayaran',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    centerTitle: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: darkText),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  body: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      // ===============================
                      // 1. CAR CARD
                      // ===============================
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9ECF2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 85,
                                height: 60,
                                color: const Color(0xFFF2F4F7),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.directions_car,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : const Icon(Icons.directions_car,
                                        color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF2F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$transmission • $capacity Kursi',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5A6474),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$carName ($year)',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: darkText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _formatCurrency(pricePerDay),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: primaryBlue,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' /hari',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===============================
                      // 2. RINGKASAN JADWAL SEWA
                      // ===============================
                      const Text(
                        'Ringkasan Jadwal Sewa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE9ECF2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Mulai Sewa',
                                      style: TextStyle(
                                          fontSize: 11, color: mutedText)),
                                  const SizedBox(height: 4),
                                  Text(_formatDateShort(_start),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: darkText)),
                                  const SizedBox(height: 2),
                                  const Text('09:00 WIB',
                                      style: TextStyle(
                                          fontSize: 11, color: mutedText)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE9ECF2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Selesai Sewa',
                                      style: TextStyle(
                                          fontSize: 11, color: mutedText)),
                                  const SizedBox(height: 4),
                                  Text(_formatDateShort(_end),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: darkText)),
                                  const SizedBox(height: 2),
                                  const Text('09:00 WIB',
                                      style: TextStyle(
                                          fontSize: 11, color: mutedText)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ===============================
                      // 3. DATA PENYEWA
                      // ===============================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Data Penyewa',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF0FA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security,
                                    size: 12, color: Color(0xFF5A6474)),
                                SizedBox(width: 4),
                                Text('Terlindungi',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5A6474),
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9ECF2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFDEE6F3),
                                  child: Text(
                                    _getInitials(userName),
                                    style: const TextStyle(
                                        color: Color(0xFF2C3E55),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: darkText),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone,
                                              size: 12, color: mutedText),
                                          const SizedBox(width: 4),
                                          Text(
                                            userPhone,
                                            style: const TextStyle(
                                                fontSize: 12, color: mutedText),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F5FF),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFD6E4FF)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_user_rounded,
                                      color: primaryBlue, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'KTP & SIM A Terverifikasi',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: primaryBlue),
                                    ),
                                  ),
                                  Icon(Icons.check_circle,
                                      color: primaryBlue, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===============================
                      // 4. METODE SERAH TERIMA
                      // ===============================
                      const Text(
                        'Metode Serah Terima',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: darkText),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Pilih cara menerima kendaraan',
                        style: TextStyle(fontSize: 11, color: mutedText),
                      ),
                      const SizedBox(height: 10),

                      // Pilihan 1: Ambil Sendiri
                      InkWell(
                        onTap: () => setState(() => _isDelivery = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isDelivery
                                ? const Color(0xFFF2F7FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !_isDelivery
                                  ? primaryBlue
                                  : const Color(0xFFE9ECF2),
                              width: !_isDelivery ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront_outlined,
                                  color: primaryBlue, size: 22),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ambil Sendiri di Rental',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: darkText)),
                                    SizedBox(height: 2),
                                    Text('GRATIS',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: primaryBlue,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              Icon(
                                !_isDelivery
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: !_isDelivery ? primaryBlue : Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Pilihan 2: Diantar ke Alamat
                      InkWell(
                        onTap: () => setState(() => _isDelivery = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isDelivery
                                ? const Color(0xFFF2F7FF)
                                : const Color(0xFFFAFAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isDelivery
                                  ? primaryBlue
                                  : const Color(0xFFE9ECF2),
                              width: _isDelivery ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping_outlined,
                                  color:
                                      _isDelivery ? primaryBlue : Colors.grey,
                                  size: 22),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Diantar ke Alamat',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: darkText)),
                                    SizedBox(height: 2),
                                    Text('+Rp50.000 / hari',
                                        style: TextStyle(
                                            fontSize: 11, color: mutedText)),
                                  ],
                                ),
                              ),
                              Icon(
                                _isDelivery
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: _isDelivery ? primaryBlue : Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Info Box Pool (Ambil Sendiri)
                      if (!_isDelivery)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9ECF2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF2FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.storefront,
                                        color: primaryBlue, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Pool NOV Rent',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: darkText)),
                                        const SizedBox(height: 4),
                                        Text(
                                          poolAddress,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF4A5568),
                                              height: 1.4),
                                        ),
                                        const SizedBox(height: 6),
                                        const Row(
                                          children: [
                                            Icon(Icons.access_time,
                                                size: 13, color: primaryBlue),
                                            SizedBox(width: 4),
                                            Text(
                                                'Buka Setiap Hari: 07:00 - 22:00 WIB',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF4A5568))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        final mapsUrl =
                                            'https://www.google.com/maps/search/?api=1&query=$poolLat,$poolLng';
                                        Clipboard.setData(
                                            ClipboardData(text: mapsUrl));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Link Google Maps ($poolLat, $poolLng) disalin!'),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.explore_outlined,
                                          size: 16),
                                      label: const Text('Buka di Google Maps',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: darkText,
                                        side: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                          text: poolAddress,
                                        ));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Alamat pool berhasil disalin!'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('Salin',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: darkText,
                                        side: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.discount_outlined,
                                      size: 16, color: primaryBlue),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Petugas pool kami akan menyambut Anda, melakukan cek fisik unit bersama, dan serah terima kunci serta dokumen STNK.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF4A5568),
                                          height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 15, color: primaryBlue),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Jadwal Pengambilan',
                                          style: TextStyle(
                                              fontSize: 10, color: mutedText)),
                                      Text(
                                        '${_formatDateShort(_start)} • 09:00 WIB',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: darkText),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9ECF2)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      color: primaryBlue, size: 20),
                                  SizedBox(width: 8),
                                  Text('Alamat Pengantaran',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Mobil akan diantarkan langsung ke alamat rumah atau lokasi yang kamu tentukan sebelum jadwal sewa dimulai.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4A5568),
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 18),

                      // ===============================
                      // 5. METODE PEMBAYARAN
                      // ===============================
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: darkText),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE9ECF2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _paymentBank,
                                style: const TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _paymentMethod,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: darkText),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Konfirmasi otomatis Instan',
                                    style: TextStyle(
                                        fontSize: 11, color: mutedText),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _showPaymentPicker,
                              child: const Text('Ganti',
                                  style: TextStyle(
                                      color: primaryBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const Icon(Icons.radio_button_checked,
                                color: primaryBlue, size: 18),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===============================
                      // 6. RINCIAN PEMBAYARAN
                      // ===============================
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9ECF2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rincian Pembayaran',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: darkText),
                            ),
                            const SizedBox(height: 12),
                            _priceRow(
                              'Sewa Unit ($_rentalDays hari × ${_formatCurrency(pricePerDay)})',
                              _formatCurrency(unitTotal),
                            ),
                            const SizedBox(height: 8),
                            _priceRow(
                              'Biaya Layanan & Asuransi',
                              _formatCurrency(_insuranceFee),
                            ),
                            const SizedBox(height: 8),
                            _priceRow(
                              'Biaya Antar ($_rentalDays hari × ${_formatCurrency(_deliveryPricePerDay)})',
                              _isDelivery
                                  ? _formatCurrency(deliveryFee)
                                  : 'Rp0',
                            ),
                            if (widget.withDriver) ...[
                              const SizedBox(height: 8),
                              _priceRow(
                                'Biaya Sopir ($_rentalDays hari × ${_formatCurrency(_driverPricePerDay)})',
                                _formatCurrency(driverFee),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              _priceRow(
                                'Biaya Sopir ($_rentalDays hari × ${_formatCurrency(_driverPricePerDay)})',
                                'Rp0',
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFE9ECF2)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Tagihan Saat Ini',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: darkText),
                                ),
                                Text(
                                  _formatCurrency(grandTotal),
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      size: 15, color: primaryBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      !_isDelivery
                                          ? 'Ambil sendiri tidak dikenakan biaya antar.'
                                          : 'Mobil akan diantarkan tepat waktu ke lokasi Anda.',
                                      style: const TextStyle(
                                          fontSize: 11, color: primaryBlue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFEAECF0))),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Pembayaran',
                                      style: TextStyle(
                                          fontSize: 11, color: mutedText)),
                                  Text(
                                    _formatCurrency(grandTotal),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: darkText),
                                  ),
                                ],
                              ),
                              Text(
                                !_isDelivery ? 'Ambil Sendiri' : 'Diantar',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => _handlePayment(car, user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Bayar Sekarang',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(_formatCurrency(grandTotal),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: darkText)),
      ],
    );
  }
}
