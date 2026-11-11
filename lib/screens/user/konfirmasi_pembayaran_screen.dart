import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/app_constants.dart';

class KonfirmasiPembayaranScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const KonfirmasiPembayaranScreen({
    super.key,
    required this.data,
  });

  @override
  State<KonfirmasiPembayaranScreen> createState() => _KonfirmasiPembayaranScreenState();
}

class _KonfirmasiPembayaranScreenState extends State<KonfirmasiPembayaranScreen> {
  static const Color primaryBlue = AppColors.primary;
  static const Color darkText = AppColors.textDark;
  static const Color mutedText = AppColors.textMuted;
  static const Color lightBg = AppColors.background;

  final ImagePicker _picker = ImagePicker();
  XFile? _proofFile;
  Uint8List? _proofBytes;

  late String _orderNumber;
  bool _isSubmitting = false;

  // Countdown Timer 24 Jam
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Generate nomor order unik, contoh: #NOV-20241118-8849
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomNum = 1000 + Random().nextInt(9000);
    _orderNumber = 'NOV-$dateStr-$randomNum';

    // 23 jam 59 menit 59 detik
    _remainingSeconds = 24 * 3600 - 1;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatCurrency(num value) => AppFormatters.rupiah(value);
  String _formatDate(DateTime date) => AppFormatters.dateWithYear(date);

  Future<void> _pickProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto dari Kamera'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final file = await _picker.pickImage(source: source);
      if (file == null) return;

      if (await file.length() > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ukuran foto maksimal 5 MB.')),
          );
        }
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _proofFile = file;
        _proofBytes = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  Future<void> _submitPayment({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih foto bukti pembayaran terlebih dahulu.')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload bukti transfer ke Cloudinary
      final proofUrl = await CloudinaryService.uploadImage(
        file: _proofFile!,
        folder: 'payments/${currentUser.uid}',
      );

      final carId = widget.data['carId']?.toString() ?? '';
      final carName = widget.data['carName']?.toString() ?? 'Mobil';
      final carImage = widget.data['carImage']?.toString() ?? '';
      final userName = widget.data['userName']?.toString() ?? 'Customer';
      final userPhone = widget.data['userPhone']?.toString() ?? '-';
      final startDate = widget.data['startDate'] as DateTime;
      final endDate = widget.data['endDate'] as DateTime;
      final rentalDays = widget.data['rentalDays'] as int? ?? 1;
      final serviceType = widget.data['withDriver'] == true ? 'dengan_sopir' : 'lepas_kunci';
      final deliveryMethod = widget.data['isDelivery'] == true ? 'diantar' : 'ambil_sendiri';
      final deliveryAddress = widget.data['deliveryAddress']?.toString();
      final deliveryFee = widget.data['deliveryFee'] as int? ?? 0;
      final driverFee = widget.data['driverFee'] as int? ?? 0;
      final insuranceFee = widget.data['insuranceFee'] as int? ?? 10000;
      final unitPricePerDay = widget.data['pricePerDay'] as int? ?? 350000;
      final grandTotal = widget.data['grandTotal'] as int? ?? 700000;
      final paymentMethod = widget.data['paymentMethod']?.toString() ?? 'BCA Virtual Account';

      // 2. Simpan order ke koleksi orders
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'orderNumber': _orderNumber,
        'userId': currentUser.uid,
        'userName': userName,
        'userPhone': userPhone,
        'userEmail': currentUser.email ?? '-',
        'carId': carId,
        'carName': carName,
        'carImage': carImage,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'rentalDays': rentalDays,
        'serviceType': serviceType,
        'deliveryMethod': deliveryMethod,
        'deliveryAddress': deliveryAddress,
        'deliveryFee': deliveryFee,
        'driverFee': driverFee,
        'insuranceFee': insuranceFee,
        'unitPricePerDay': unitPricePerDay,
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'menunggu_verifikasi',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Simpan data pembayaran ke koleksi payments
      await FirebaseFirestore.instance.collection('payments').add({
        'orderId': orderRef.id,
        'orderNumber': _orderNumber,
        'userId': currentUser.uid,
        'amount': grandTotal,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolder': accountHolder,
        'proofImageUrl': proofUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 4. Tampilkan dialog sukses
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Bukti Terkirim!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bukti transfer kamu telah berhasil dikirim. Admin akan segera memverifikasi pesananmu.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No. Pesanan: #$_orderNumber',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/pesanan');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Lihat Pesanan'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim bukti pembayaran: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String carName = widget.data['carName']?.toString() ?? 'Toyota Avanza 1.3 G';
    final String year = widget.data['year']?.toString() ?? '2023';
    final String carImage = widget.data['carImage']?.toString() ?? '';
    final String transmission = widget.data['transmission']?.toString() ?? 'Matic (A/T)';
    final int capacity = widget.data['capacity'] as int? ?? 7;
    final String fuelType = widget.data['fuelType']?.toString() ?? 'Bensin';
    final DateTime startDate = widget.data['startDate'] as DateTime? ?? DateTime.now();
    final DateTime endDate = widget.data['endDate'] as DateTime? ?? DateTime.now().add(const Duration(days: 2));
    final int rentalDays = widget.data['rentalDays'] as int? ?? 2;
    final bool withDriver = widget.data['withDriver'] == true;
    final bool isDelivery = widget.data['isDelivery'] == true;
    final int grandTotal = widget.data['grandTotal'] as int? ?? 700000;
    final String paymentBank = widget.data['paymentBank']?.toString() ?? 'BCA';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('settings').doc('general').snapshots(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data?.data() ?? {};
        final poolAddress = settings['poolAddress']?.toString() ?? 'Pool NOV Rent Tebet, Jaksel';

        // Cari rekening sesuai bank yang dipilih
        String targetBankName = 'Bank Central Asia';
        String targetAccountHolder = 'PT NOV RENT DYNAMIC INDONESIA';
        String targetAccountNumber = '8820 4910 2341';

        final bankAccounts = settings['bankAccounts'] as List<dynamic>?;
        if (bankAccounts != null && bankAccounts.isNotEmpty) {
          final matched = bankAccounts.firstWhere(
            (acc) => acc is Map && acc['bankName']?.toString().toUpperCase() == paymentBank.toUpperCase(),
            orElse: () => null,
          );

          if (matched != null && matched is Map) {
            targetAccountHolder = matched['accountHolder']?.toString() ?? targetAccountHolder;
            targetAccountNumber = matched['accountNumber']?.toString() ?? targetAccountNumber;
            final bName = matched['bankName']?.toString() ?? paymentBank;
            if (bName.toUpperCase() == 'BCA') {
              targetBankName = 'Bank Central Asia';
            } else if (bName.toUpperCase() == 'BRI') {
              targetBankName = 'Bank Rakyat Indonesia';
            } else if (bName.toUpperCase() == 'MANDIRI') {
              targetBankName = 'Bank Mandiri';
            } else {
              targetBankName = bName;
            }
          }
        }

        return Scaffold(
          backgroundColor: lightBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: darkText),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Konfirmasi Pembayaran',
              style: TextStyle(
                color: darkText,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===============================
              // LANGKAH TERAKHIR & TIMER
              // ===============================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECF2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, color: primaryBlue, size: 10),
                        SizedBox(width: 8),
                        Text(
                          'Langkah Terakhir',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A5568)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFFD92D20), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimer(_remainingSeconds),
                            style: const TextStyle(
                              color: Color(0xFFD92D20),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ===============================
              // CARD 1: RINGKASAN SEWA
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Ringkasan Sewa',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#$_orderNumber',
                          style: const TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            withDriver ? 'Dengan Sopir' : 'Lepas Kunci',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4A5568)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80,
                            height: 60,
                            color: const Color(0xFFF2F4F7),
                            child: carImage.isNotEmpty
                                ? Image.network(
                                    carImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: Colors.grey),
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
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Tahun $year · Warna Standar',
                                style: const TextStyle(fontSize: 11, color: mutedText),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _badgeChip(transmission),
                                  _badgeChip('$capacity Kursi'),
                                  _badgeChip(fuelType),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE9ECF2)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 15, color: mutedText),
                        const SizedBox(width: 8),
                        const Text('Durasi Sewa', style: TextStyle(fontSize: 11, color: mutedText)),
                        const Spacer(),
                        Text(
                          '${_formatDate(startDate)} – ${_formatDate(endDate)} ($rentalDays Hari)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 15, color: mutedText),
                        const SizedBox(width: 8),
                        const Text('Metode Ambil', style: TextStyle(fontSize: 11, color: mutedText)),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            isDelivery ? 'Diantar ke Alamat' : poolAddress,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkText),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ===============================
              // CARD 2: REKENING BANK TUJUAN
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            paymentBank,
                            style: const TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    targetBankName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: primaryBlue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Resmi', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                targetAccountHolder,
                                style: const TextStyle(fontSize: 11, color: mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Kotak Nomor Rekening
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NOMOR REKENING TUJUAN', style: TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                targetAccountNumber,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: darkText, letterSpacing: 1),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: targetAccountNumber.replaceAll(' ', '')));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nomor rekening berhasil disalin!'), duration: Duration(seconds: 2)),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 14, color: primaryBlue),
                            label: const Text('Salin', style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFEBF2FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Kotak Total Tagihan
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL TAGIHAN BERSIH', style: TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(grandTotal),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryBlue),
                              ),
                              const SizedBox(height: 2),
                              const Text('Termasuk pajak', style: TextStyle(fontSize: 10, color: mutedText)),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: grandTotal.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nominal tagihan berhasil disalin!'), duration: Duration(seconds: 2)),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 14, color: primaryBlue),
                            label: const Text('Salin', style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFEBF2FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ===============================
              // CARD 3: BUKTI PEMBAYARAN
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
                    const Row(
                      children: [
                        Text('Bukti Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
                        SizedBox(width: 4),
                        Icon(Icons.circle, size: 6, color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Format: JPG, PNG, atau PDF · Maks. 5 MB', style: TextStyle(fontSize: 11, color: mutedText)),
                    const SizedBox(height: 12),

                    // Area Upload / Preview
                    InkWell(
                      onTap: _pickProof,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_proofBytes != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _proofBytes!,
                                  height: 130,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('Foto dipilih. Ketuk untuk mengganti.', style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600)),
                            ] else ...[
                              Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD6E4FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_upload_outlined, color: primaryBlue, size: 28),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Ketuk untuk unggah bukti transfer',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkText),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pilih berkas struk ATM, tangkapan layar m-\nBanking, atau struk internet banking Anda',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: mutedText, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCE6F5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.insert_photo_outlined, size: 14, color: Color(0xFF3A4B68)),
                                    SizedBox(width: 6),
                                    Text('Pilih Dokumen / Foto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3A4B68))),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Kendala transfer? Hubungi CS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.help_outline, size: 14, color: mutedText),
                            SizedBox(width: 6),
                            Text('Mengalami kendala transfer?', style: TextStyle(fontSize: 11, color: mutedText)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Menghubungi Customer Service NOV Rent...')),
                            );
                          },
                          child: const Text('Hubungi CS 24/7', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue)),
                        ),
                      ],
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
                          const Text('TOTAL PEMBAYARAN', style: TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.w600)),
                          Text(
                            _formatCurrency(grandTotal),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _proofFile == null || _isSubmitting
                              ? null
                              : () => _submitPayment(
                                    bankName: targetBankName,
                                    accountNumber: targetAccountNumber,
                                    accountHolder: targetAccountHolder,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE2E6EE),
                            disabledForegroundColor: const Color(0xFF8A94A6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  children: [
                                    Text('Kirim Bukti Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward, size: 15),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: mutedText),
                      SizedBox(width: 4),
                      Text(
                        'Lengkapi bukti transfer dan nama pengirim untuk mengirim',
                        style: TextStyle(fontSize: 10, color: mutedText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badgeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF5A6474), fontWeight: FontWeight.w500),
      ),
    );
  }
}
