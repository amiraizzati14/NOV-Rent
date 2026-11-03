import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'detail_screen.dart';

const Color primaryBlue = Color(0xFF0057C2);
const Color backgroundColor = Color(0xFFF7F7FA);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedService = 'self_drive';

  String selectedLocation = 'Bandar Udara Juanda (SUB), Surabaya';

  DateTime? startDate;
  DateTime? endDate;

  int selectedBottomIndex = 0;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ==========================================
  // FIRESTORE
  // ==========================================

  Stream<QuerySnapshot<Map<String, dynamic>>> get carsStream {
    return firestore
        .collection('cars')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  // ==========================================
  // FORMAT DATE
  // ==========================================

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Pilih tanggal';
    }

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
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  // ==========================================
  // SELECT DATE
  // ==========================================

  Future<void> selectDate(bool isStart) async {
    final now = DateTime.now();

    final initialDate =
        isStart ? startDate ?? now : endDate ?? startDate ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate == null) return;

    setState(() {
      if (isStart) {
        startDate = pickedDate;

        if (endDate != null && endDate!.isBefore(pickedDate)) {
          endDate = null;
        }
      } else {
        if (startDate != null && pickedDate.isBefore(startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tanggal selesai tidak boleh sebelum tanggal mulai',
              ),
            ),
          );

          return;
        }

        endDate = pickedDate;
      }
    });
  }

  // ==========================================
  // SEARCH
  // ==========================================

  void searchCars() {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih tanggal mulai dan selesai',
          ),
        ),
      );

      return;
    }

    if (!endDate!.isAfter(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tanggal selesai harus setelah tanggal mulai',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tanggal sewa berhasil dipilih',
        ),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // ==========================================
      // APP BAR
      // ==========================================

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'NOV RENT',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      // ==========================================
      // BODY
      // ==========================================

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: carsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Gagal mengambil data mobil\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryBlue,
                ),
              );
            }

            final cars = snapshot.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                14,
                4,
                14,
                20,
              ),
              children: [
                // ==========================================
                // HEADER
                // ==========================================

                const Text(
                  'Temukan mobil untuk\nperjalananmu.',
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Armada bersih, terawat, dan siap mengantar petualangan Anda.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 14),

                // ==========================================
                // SEARCH CARD
                // ==========================================

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      // SERVICE TYPE

                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: serviceButton(
                                'Lepas Kunci',
                                'self_drive',
                              ),
                            ),
                            Expanded(
                              child: serviceButton(
                                'Dengan Sopir',
                                'with_driver',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // LOCATION

                      InkWell(
                        onTap: showLocationOptions,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lokasi Penjemputan',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      selectedLocation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // DATE

                      Row(
                        children: [
                          Expanded(
                            child: dateBox(
                              'Mulai Sewa',
                              startDate,
                              () => selectDate(true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: dateBox(
                              'Selesai Sewa',
                              endDate,
                              () => selectDate(false),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // SEARCH BUTTON

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: searchCars,
                          icon: const Icon(
                            Icons.search,
                            size: 17,
                          ),
                          label: const Text(
                            'Cari Mobil Tersedia',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================================
                // BRAND
                // ==========================================

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Merek Pilihan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          fontSize: 11,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                brandSection(cars),

                const SizedBox(height: 24),

                // ==========================================
                // AVAILABLE CARS
                // ==========================================

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tersedia di dekatmu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          fontSize: 11,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const Text(
                  'Unit terdekat siap antar dalam 45 menit',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 12),

                if (cars.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Belum ada mobil tersedia',
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final document = cars[index];

                        return SizedBox(
                          width: 230,
                          child: HomeCarCard(
                            carId: document.id,
                            car: document.data(),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // ==========================================
                // PROMO
                // ==========================================

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFD9AD),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jaminan Bebas Cemas',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Asuransi menyeluruh dan unit bersih.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // ==========================================
      // BOTTOM NAVIGATION
      // ==========================================
    );
  }

  // ==========================================
  // SERVICE BUTTON
  // ==========================================

  Widget serviceButton(String title, String value) {
    final isSelected = selectedService == value;

    return InkWell(
      onTap: () {
        setState(() {
          selectedService = value;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DATE BOX
  // ==========================================

  Widget dateBox(
    String title,
    DateTime? date,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F7),
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
              formatDate(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LOCATION OPTIONS
  // ==========================================

  void showLocationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Lokasi Penjemputan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: primaryBlue,
                ),
                title: const Text(
                  'Bandar Udara Juanda (SUB), Surabaya',
                ),
                onTap: () {
                  setState(() {
                    selectedLocation = 'Bandar Udara Juanda (SUB), Surabaya';
                  });

                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: primaryBlue,
                ),
                title: const Text('Surabaya'),
                onTap: () {
                  setState(() {
                    selectedLocation = 'Surabaya';
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // BRAND SECTION
  // ==========================================

  Widget brandSection(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> cars,
  ) {
    final brands = cars
        .map((document) {
          return document.data()['brand']?.toString() ?? '';
        })
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList();

    if (brands.isEmpty) {
      return const Text(
        'Belum ada merek mobil',
        style: TextStyle(color: Colors.grey),
      );
    }

    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final brand = brands[index];

          return Container(
            width: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_car_outlined,
                  color: primaryBlue,
                  size: 25,
                ),
                const SizedBox(height: 8),
                Text(
                  brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// CAR CARD
// ==========================================

class HomeCarCard extends StatelessWidget {
  final String carId;
  final Map<String, dynamic> car;

  const HomeCarCard({
    super.key,
    required this.carId,
    required this.car,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(
      car['imageUrls'] ?? [],
    );

    final price = car['pricePerDay'] ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              carId: carId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE

            Stack(
              children: [
                SizedBox(
                  height: 125,
                  width: double.infinity,
                  child: images.isNotEmpty
                      ? Image.network(
                          images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(
                                Icons.directions_car,
                                size: 50,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.directions_car,
                            size: 50,
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      car['year']?.toString() ?? '2023',
                      style: const TextStyle(
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            // INFORMATION

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car['category']?.toString() ?? 'Mobil',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      car['name']?.toString() ?? 'Mobil',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.settings,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            car['transmission']?.toString() ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.people_outline,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${car['capacity'] ?? '-'} Kursi',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'Mulai dari',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rp${price.toString()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          '/hari',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ],
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
}
