import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color blue = AppColors.primaryBlue;
  static const Color dark = AppColors.textDark;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _hasSearched = false;

  DateTime? _startDate;
  DateTime? _endDate;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cars = [];

  // ==========================================
  // FORMAT HARGA & TANGGAL
  // ==========================================

  String _formatPrice(dynamic price) => AppFormatters.rupiah(price);
  String _formatDate(DateTime? date) => AppFormatters.dateWithYear(date);

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
          .where('isAvailable', isEqualTo: true)
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
    if (data['imageUrl'] is String && (data['imageUrl'] as String).isNotEmpty) {
      return data['imageUrl'];
    }

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

  Widget _carCard(QueryDocumentSnapshot<Map<String, dynamic>> car,
      {bool popular = false}) {
    final data = car.data();
    final name = data['name']?.toString() ?? 'Mobil';
    final year = data['year']?.toString() ?? '-';
    final price = _formatPrice(data['pricePerDay']);
    final image = _getImage(data);
    final border = BorderRadius.circular(16);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: border,
          side: const BorderSide(color: Color(0xFFECECF1))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showCarDetail(car),
        child: popular
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  _carImage(image, height: 108),
                  Positioned(
                      top: 10,
                      left: 10,
                      child: Row(children: [
                        _badge(year, Colors.white, const Color(0xFF747C8B)),
                        const SizedBox(width: 5),
                        _badge('🔥 Populer', const Color(0xFFFFF3E8),
                            const Color(0xFFD76200)),
                      ])),
                ]),
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              (data['category'] ?? 'Mobil pilihan')
                                  .toString()
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: .7,
                                  color: Color(0xFF747C8B))),
                          const SizedBox(height: 5),
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: dark)),
                          const SizedBox(height: 7),
                          Wrap(spacing: 12, runSpacing: 4, children: [
                            _infoItem(Icons.settings_outlined,
                                (data['transmission'] ?? '-').toString()),
                            _infoItem(Icons.people_outline,
                                "${data['capacity'] ?? '-'} Kursi"),
                          ]),
                          const SizedBox(height: 8),
                          const Text('Mulai dari',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF747C8B))),
                          Row(children: [
                            Expanded(
                                child: Text.rich(
                                    TextSpan(children: [
                                      TextSpan(
                                          text: price,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: blue)),
                                      const TextSpan(
                                          text: ' /hari',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF747C8B))),
                                    ]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFFEAF2FF),
                                child: Icon(Icons.arrow_forward,
                                    size: 19, color: blue)),
                          ]),
                        ])),
              ])
            : Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: dark)),
                          const SizedBox(height: 5),
                          Text('Tahun $year',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF747C8B))),
                          const SizedBox(height: 7),
                          _infoItem(Icons.settings_outlined,
                              (data['transmission'] ?? '-').toString()),
                          const SizedBox(height: 5),
                          _infoItem(Icons.people_outline,
                              "${data['capacity'] ?? '-'} Kursi"),
                        ])),
                    const SizedBox(width: 12),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                            width: 115, child: _carImage(image, height: 80))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: price,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: dark)),
                      const TextSpan(
                          text: ' /hari', style: TextStyle(fontSize: 10)),
                    ]))),
                    const SizedBox(width: 8),
                    FilledButton(
                        onPressed: () => _showCarDetail(car),
                        style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 13)),
                        child: const Text('Pilih & Detail →',
                            style: TextStyle(fontSize: 11))),
                  ]),
                ])),
      ),
    );
  }

  Widget _badge(String label, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 10, color: foreground)),
      );

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
    if (_cars.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child:
              Center(child: Text('Belum ada mobil dengan status tersedia.')));
    }
    // Khusus mobil yang memiliki status isPopular == true
    final popular = _cars.where((car) {
      final isPop = car.data()['isPopular'];
      return isPop == true || isPop?.toString().toLowerCase() == 'true';
    }).toList();
    final sorted = [..._cars]..sort((a, b) =>
        _priceValue(a.data()['pricePerDay'])
            .compareTo(_priceValue(b.data()['pricePerDay'])));
    final catalog = sorted.take(5).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (popular.isNotEmpty) ...[
        const Text('Mobil Populer',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: dark)),
        const SizedBox(height: 4),
        const Text('Pilihan mobil untuk perjalananmu',
            style: TextStyle(fontSize: 11, color: Color(0xFF858B96))),
        const SizedBox(height: 12),
        // Hanya bagian ini yang scroll horizontal. Tinggi mengikuti skala teks.
        SizedBox(
          height: 118 + 146 * MediaQuery.textScalerOf(context).scale(1),
          child: LayoutBuilder(builder: (context, constraints) {
            final width =
                (constraints.maxWidth * .72).clamp(215.0, 255.0).toDouble();
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 13),
              itemBuilder: (context, index) => SizedBox(
                  width: width, child: _carCard(popular[index], popular: true)),
            );
          }),
        ),
        const SizedBox(height: 14),
      ],
      const Row(children: [
        Icon(Icons.circle, size: 7, color: blue),
        SizedBox(width: 7),
        Expanded(
            child: Text('Keseluruhan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        Text('Termurah ke termahal',
            style: TextStyle(fontSize: 10, color: blue)),
        SizedBox(width: 3),
        Icon(Icons.sort, size: 15, color: blue),
      ]),
      const SizedBox(height: 6),
      Text(
          '${catalog.length} mobil • ${_formatDate(_startDate)} – ${_formatDate(_endDate)}',
          style: const TextStyle(fontSize: 10, color: Color(0xFF858B96))),
      const SizedBox(height: 12),
      // Kartu mengikuti ListView utama, tanpa scroll vertikal bersarang.
      for (final car in catalog) ...[
        _carCard(car),
        const SizedBox(height: 12),
      ],
    ]);
  }

  num _priceValue(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      child: SizedBox(
        height: 43,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NOV RENT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: dark,
              ),
            ),
            Icon(
              Icons.notifications_none,
              size: 22,
              color: dark,
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
