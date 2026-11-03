import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetailScreen extends StatelessWidget {
  final String carId;

  const DetailScreen({
    super.key,
    required this.carId,
  });

  static const Color primaryColor = Color(0xFF0057C2);
  static const Color backgroundColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('cars')
            .doc(carId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return _errorView(
              context,
              'Gagal mengambil data mobil.\n${snapshot.error}',
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _errorView(
              context,
              'Data mobil tidak ditemukan.',
            );
          }

          final car = snapshot.data!.data()!;

          final String name = car['name']?.toString() ?? 'Mobil';
          final String brand = car['brand']?.toString() ?? '-';
          final String category = car['category']?.toString() ?? '-';
          final String description =
              car['description']?.toString() ?? 'Belum ada deskripsi mobil.';

          final String transmission = car['transmission']?.toString() ?? '-';

          final String fuelType = car['fuelType']?.toString() ?? '-';

          final int capacity = _toInt(car['capacity']);

          final int pricePerDay = _toInt(car['pricePerDay']);

          final String status = car['status']?.toString() ?? 'available';

          final List<String> imageUrls = _getImageUrls(car['imageUrls']);

          return _buildDetailPage(
            context: context,
            name: name,
            brand: brand,
            category: category,
            description: description,
            transmission: transmission,
            fuelType: fuelType,
            capacity: capacity,
            pricePerDay: pricePerDay,
            status: status,
            imageUrls: imageUrls,
          );
        },
      ),
    );
  }

  Widget _buildDetailPage({
    required BuildContext context,
    required String name,
    required String brand,
    required String category,
    required String description,
    required String transmission,
    required String fuelType,
    required int capacity,
    required int pricePerDay,
    required String status,
    required List<String> imageUrls,
  }) {
    return SafeArea(
      child: Column(
        children: [
          // HEADER
          _buildHeader(context),

          // CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CAR IMAGE
                  _buildCarImage(imageUrls),

                  const SizedBox(height: 18),

                  // CAR NAME
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF171923),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '$brand • $category',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildFavoriteButton(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // STATUS
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: _buildStatus(status),
                  ),

                  const SizedBox(height: 22),

                  // INFORMATION
                  _buildSectionTitle('Informasi Mobil'),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _infoCard(
                                icon: Icons.people_outline,
                                title: 'Kapasitas',
                                value: '$capacity Penumpang',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _infoCard(
                                icon: Icons.door_front_door_outlined,
                                title: 'Jumlah Pintu',
                                value: '5 Pintu',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _infoCard(
                                icon: Icons.ac_unit,
                                title: 'Pendingin',
                                value: 'AC Double Blower',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _infoCard(
                                icon: Icons.settings_outlined,
                                title: 'Transmisi',
                                value: transmission,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _infoCard(
                          icon: Icons.local_gas_station_outlined,
                          title: 'Bahan Bakar',
                          value: fuelType,
                          fullWidth: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // EXTRA SPECIFICATION
                  _buildSectionTitle('Spesifikasi Tambahan'),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _specCard(
                            icon: Icons.luggage_outlined,
                            title: 'Bagasi',
                            value: '3 Koper Besar',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _specCard(
                            icon: Icons.calendar_month_outlined,
                            title: 'Tahun',
                            value: '-',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _specCard(
                            icon: Icons.speed_outlined,
                            title: 'Mesin',
                            value: '-',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // DESCRIPTION
                  _buildSectionTitle('Deskripsi Mobil'),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Color(0xFF666A75),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // RENTAL TERMS
                  _buildSectionTitle('Ketentuan Sewa Singkat'),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        _termCard(
                          Icons.cleaning_services_outlined,
                          'Unit steril, higienis & disinfeksi sebelum serah terima',
                        ),
                        const SizedBox(height: 8),
                        _termCard(
                          Icons.shield_outlined,
                          'Termasuk asuransi standar komprehensif all-risk',
                        ),
                        const SizedBox(height: 8),
                        _termCard(
                          Icons.local_gas_station_outlined,
                          'Kebijakan BBM fair-to-fair (kembali sesuai posisi awal)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // BOTTOM PRICE
          _buildBottomPrice(
            context,
            pricePerDay,
            status,
          ),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEDEEF3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Detail Mobil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // CAR IMAGE
  Widget _buildCarImage(List<String> imageUrls) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        0,
      ),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrls.isNotEmpty
          ? Image.network(
              imageUrls.first,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _imagePlaceholder();
              },
            )
          : _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE8EAF0),
      child: const Center(
        child: Icon(
          Icons.directions_car,
          size: 70,
          color: Colors.grey,
        ),
      ),
    );
  }

  // FAVORITE
  Widget _buildFavoriteButton() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE7E8ED),
        ),
      ),
      child: const Icon(
        Icons.favorite_border,
        color: Color(0xFF5E6470),
      ),
    );
  }

  // STATUS
  Widget _buildStatus(String status) {
    final bool available = status.toLowerCase() == 'available';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE8F7EE) : const Color(0xFFFFF0E7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_outline : Icons.info_outline,
            size: 18,
            color: available ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              available
                  ? 'Mobil tersedia untuk disewa'
                  : 'Status mobil: $status',
              style: TextStyle(
                fontSize: 12,
                color:
                    available ? Colors.green.shade800 : Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION TITLE
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF20232C),
        ),
      ),
    );
  }

  // INFORMATION CARD
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF282B35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SPECIFICATION CARD
  Widget _specCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 23,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // RENTAL TERMS
  Widget _termCard(
    IconData icon,
    String text,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF555B67),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM PRICE
  Widget _buildBottomPrice(
    BuildContext context,
    int pricePerDay,
    String status,
  ) {
    final bool available = status.toLowerCase() == 'available';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8E9EF),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tarif Sewa',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _formatRupiah(pricePerDay),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const TextSpan(
                          text: ' /hari',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: available
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur pilih tanggal akan segera tersedia.',
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Pilih Tanggal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ERROR VIEW
  Widget _errorView(
    BuildContext context,
    String message,
  ) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detail Mobil'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // IMAGE URLS
  List<String> _getImageUrls(dynamic value) {
    if (value is List) {
      return value.whereType<String>().where((url) => url.isNotEmpty).toList();
    }

    if (value is String && value.isNotEmpty) {
      return [value];
    }

    return [];
  }

  // NUMBER CONVERSION
  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  // RUPIAH FORMAT
  String _formatRupiah(int value) {
    final String digits = value.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      result.write(digits[i]);

      final int remaining = digits.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return 'Rp$result';
  }
}
