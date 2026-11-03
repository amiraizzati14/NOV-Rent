import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color blue = Color(0xFF005BCB);
  static const Color dark = Color(0xFF202124);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _withDriver = false;
  bool _isLoading = false;
  bool _hasSearched = false;

  DateTime? _startDate;
  DateTime? _endDate;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cars = [];

  // ==========================================
  // FORMAT HARGA
  // ==========================================

  String _formatPrice(dynamic price) {
    final value = (price as num?)?.toInt() ?? 0;

    return 'Rp${value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  // ==========================================
  // FORMAT TANGGAL
  // ==========================================

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ==========================================
  // PILIH TANGGAL
  // ==========================================

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final firstDate = isStart
        ? today
        : (_startDate ?? today).add(
            const Duration(days: 1),
          );

    final initialDate =
        isStart ? (_startDate ?? today) : (_endDate ?? firstDate);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = selected;

        if (_endDate != null && !_endDate!.isAfter(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }

      // Hasil lama disembunyikan ketika tanggal berubah.
      _hasSearched = false;
      _cars.clear();
    });
  }

  // ==========================================
  // CARI MOBIL DARI FIRESTORE
  // ==========================================

  Future<void> _searchCars() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih tanggal mulai dan selesai.',
          ),
        ),
      );
      return;
    }

    if (!_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tanggal selesai harus setelah tanggal mulai.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });

    try {
      final snapshot = await _db
          .collection('cars')
          .where('status', isEqualTo: 'available')
          .get();

      if (!mounted) return;

      setState(() {
        _cars = snapshot.docs;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data mobil: $e'),
        ),
      );
    }
  }

  // ==========================================
  // GAMBAR MOBIL
  // ==========================================

  String _getImage(Map<String, dynamic> data) {
    final images = data['imageUrls'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    return '';
  }

  Widget _carImage(
    String url, {
    double height = 150,
  }) {
    if (url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFF0F1F5),
        child: const Icon(
          Icons.directions_car,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      url,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          height: height,
          color: const Color(0xFFF0F1F5),
          child: const Icon(
            Icons.directions_car,
            size: 50,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  // ==========================================
  // PILIH MODE SEWA
  // ==========================================

  Widget _modeButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected ? blue : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : dark,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // KOTAK TANGGAL
  // ==========================================

  Widget _dateBox({
    required String title,
    required String date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F7),
            borderRadius: BorderRadius.circular(10),
          ),
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
              const SizedBox(height: 5),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FORM PENCARIAN
  // ==========================================

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9E9EF),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEEF1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                _modeButton(
                  title: 'Lepas Kunci',
                  selected: !_withDriver,
                  onTap: () {
                    setState(() {
                      _withDriver = false;
                      _hasSearched = false;
                    });
                  },
                ),
                _modeButton(
                  title: 'Dengan Sopir',
                  selected: _withDriver,
                  onTap: () {
                    setState(() {
                      _withDriver = true;
                      _hasSearched = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dateBox(
                title: 'Mulai Sewa',
                date: _formatDate(_startDate),
                onTap: () => _selectDate(true),
              ),
              const SizedBox(width: 9),
              _dateBox(
                title: 'Selesai Sewa',
                date: _formatDate(_endDate),
                onTap: () => _selectDate(false),
              ),
            ],
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _searchCars,
              icon: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search, size: 17),
              label: Text(
                _isLoading ? 'Mencari Mobil...' : 'Cari Mobil Tersedia',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFO MOBIL
  // ==========================================

  Widget _infoItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD MOBIL
  // ==========================================

  Widget _carCard(
    QueryDocumentSnapshot<Map<String, dynamic>> car,
  ) {
    final data = car.data();

    final name = data['name']?.toString() ?? 'Mobil';
    final brand = data['brand']?.toString() ?? '-';
    final category = data['category']?.toString() ?? '-';
    final year = data['year']?.toString() ?? '-';
    final transmission = data['transmission']?.toString() ?? '-';
    final capacity = data['capacity']?.toString() ?? '-';
    final price = data['pricePerDay'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFECECF1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                _carImage(_getImage(data), height: 155),
                Positioned(
                  top: 9,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      year,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            brand,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 15,
            children: [
              _infoItem(
                Icons.settings,
                transmission,
              ),
              _infoItem(
                Icons.people_outline,
                '$capacity Kursi',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harga sewa',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        fontSize: 17,
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'per hari',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showCarDetail(car),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'Pilih & Detail →',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DETAIL MOBIL
  // ==========================================

  void _showCarDetail(
    QueryDocumentSnapshot<Map<String, dynamic>> car,
  ) {
    context.push('/detail/${car.id}');
  }

  // ==========================================
  // HASIL KATALOG
  // ==========================================

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.circle,
              size: 8,
              color: blue,
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'Mobil Tersedia',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${_cars.length} Mobil',
              style: const TextStyle(
                fontSize: 11,
                color: blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 13),
        if (_cars.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                Text(
                  'Mobil belum tersedia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Belum ada mobil dengan status available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        else
          ..._cars.map((car) => _carCard(car)),
      ],
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      child: SizedBox(
        height: 43,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 22,
              color: dark,
            ),
            const Text(
              'NOV RENT',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFFE1E7F2),
              child: Icon(
                Icons.person,
                size: 19,
                color: blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MAIN
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  15,
                  13,
                  15,
                  25,
                ),
                children: [
                  const Text(
                    'Temukan mobil untuk\nperjalananmu.',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Bersih, terawat, dan siap mengantar petualangan Anda.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF858B96),
                    ),
                  ),
                  const SizedBox(height: 13),
                  _buildSearchCard(),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: blue,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Sedang mengambil data mobil...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_hasSearched)
                    _buildResults()
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 35,
                        horizontal: 15,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 43,
                            color: blue,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Cari Mobil untuk Perjalananmu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Pilih tanggal sewa kemudian tekan Cari Mobil Tersedia untuk melihat katalog mobil.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              height: 1.5,
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
    );
  }
}
