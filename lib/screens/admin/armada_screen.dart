import 'package:flutter/material.dart';

/// NOV Rent - Admin Armada.
///
/// UI uses demo data. Replace [demoCars] with your repository / Firebase data.
/// Optional callbacks let the parent wire routes and business actions.
class ArmadaScreen extends StatefulWidget {
  const ArmadaScreen({
    super.key,
    this.cars = demoCars,
    this.onAdd,
    this.onSchedule,
    this.onEdit,
    this.onRentalDetail,
    this.onNavTap,
  });

  final List<ArmadaCar> cars;
  final VoidCallback? onAdd;
  final ValueChanged<ArmadaCar>? onSchedule;
  final ValueChanged<ArmadaCar>? onEdit;
  final ValueChanged<ArmadaCar>? onRentalDetail;
  /// Index: 0 Beranda, 1 Armada, 2 Pesanan, 3 Bayar, 4 Menu.
  final ValueChanged<int>? onNavTap;

  @override
  State<ArmadaScreen> createState() => _ArmadaScreenState();
}

enum ArmadaStatus { available, rented }

enum ArmadaFilter { all, available, rented }

class ArmadaCar {
  const ArmadaCar({
    required this.id,
    required this.name,
    required this.plate,
    required this.colorName,
    required this.dailyPrice,
    required this.year,
    required this.seats,
    required this.transmission,
    required this.fuel,
    required this.status,
    this.imageAsset,
    this.renter,
    this.returnInfo,
    this.isHybrid = false,
  });

  final String id;
  final String name;
  final String plate;
  final String colorName;
  final int dailyPrice;
  final int year;
  final int seats;
  final String transmission;
  final String fuel;
  final ArmadaStatus status;
  final String? imageAsset;
  final String? renter;
  final String? returnInfo;
  final bool isHybrid;
}

const demoCars = <ArmadaCar>[
  ArmadaCar(
    id: 'avanza-01', name: 'Toyota Avanza 1.5 G', plate: 'B 2341 NOV',
    colorName: 'Putih Metalik', dailyPrice: 350000, year: 2023,
    seats: 7, transmission: 'Manual', fuel: 'Bensin',
    status: ArmadaStatus.available,
    imageAsset: 'assets/images/avanza.png',
  ),
  ArmadaCar(
    id: 'xpander-01', name: 'Mitsubishi Xpander Ultimate', plate: 'B 1942 NOV',
    colorName: 'Hitam Metalik', dailyPrice: 450000, year: 2023,
    seats: 7, transmission: 'Matic', fuel: 'Bensin',
    status: ArmadaStatus.rented, renter: 'Bpk. Rian H.',
    returnInfo: 'Hingga 26 Okt 2024 (17:00)',
    imageAsset: 'assets/images/xpander.png',
  ),
  ArmadaCar(
    id: 'zenix-01', name: 'Toyota Innova Zenix', plate: 'B 1109 NOV',
    colorName: 'Abu-abu Graphite', dailyPrice: 650000, year: 2024,
    seats: 7, transmission: 'Matic', fuel: 'Hybrid', isHybrid: true,
    status: ArmadaStatus.available,
    imageAsset: 'assets/images/zenix.png',
  ),
];

class _ArmadaScreenState extends State<ArmadaScreen> {
  static const blue = Color(0xFF2346B8);
  static const ink = Color(0xFF182238);
  static const muted = Color(0xFF697184);
  static const surface = Color(0xFFF7F8FA);

  final _searchController = TextEditingController();
  ArmadaFilter _filter = ArmadaFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ArmadaCar> get _filteredCars {
    final search = _searchController.text.trim().toLowerCase();
    return widget.cars.where((car) {
      final matchesStatus = switch (_filter) {
        ArmadaFilter.all => true,
        ArmadaFilter.available => car.status == ArmadaStatus.available,
        ArmadaFilter.rented => car.status == ArmadaStatus.rented,
      };
      final matchesSearch = search.isEmpty ||
          '${car.name} ${car.plate} ${car.colorName} ${car.transmission}'
              .toLowerCase().contains(search);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  int get _availableCount => widget.cars
      .where((car) => car.status == ArmadaStatus.available).length;

  int get _rentedCount => widget.cars
      .where((car) => car.status == ArmadaStatus.rented).length;

  void _comingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hubungkan aksi "$action" ke route / fungsi aplikasi kamu.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 9),
                        child: _searchBar(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: _filters(),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cars = _filteredCars;
                            if (cars.isEmpty) return _emptyState();
                            if (constraints.maxWidth < 650) {
                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                                itemCount: cars.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, index) => _carCard(cars[index]),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 430,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 285,
                              ),
                              itemCount: cars.length,
                              itemBuilder: (_, index) => _carCard(cars[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() => Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAEDF3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: muted, size: 19),
                  const SizedBox(width: 7),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 12, color: ink),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Cari merek, tipe, plat...',
                        hintStyle: TextStyle(fontSize: 12, color: muted),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(_searchController.clear),
                      child: const Icon(Icons.close, size: 17, color: muted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: widget.onAdd ?? () => _comingSoon('Tambah armada'),
              icon: const Icon(Icons.add_circle_outline, size: 17),
              label: const Text('Tambah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3263ED),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );

  Widget _filters() => Row(
        children: [
          _filterChip(ArmadaFilter.all, 'Semua', widget.cars.length, blue),
          const SizedBox(width: 6),
          _filterChip(ArmadaFilter.available, 'Tersedia', _availableCount,
              const Color(0xFF16A865)),
          const SizedBox(width: 6),
          _filterChip(ArmadaFilter.rented, 'Sedang Disewa', _rentedCount,
              const Color(0xFF3263ED)),
        ],
      );

  Widget _filterChip(ArmadaFilter filter, String name, int count, Color color) {
    final active = _filter == filter;
    return Flexible(
      child: InkWell(
        onTap: () => setState(() => _filter = filter),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: active ? blue : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!active) ...[
                CircleAvatar(radius: 3, backgroundColor: color),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: active ? Colors.white : ink,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 5),
              Text('$count', style: TextStyle(fontSize: 10,
                  color: active ? Colors.white : muted,
                  fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carCard(ArmadaCar car) {
    final rented = car.status == ArmadaStatus.rented;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF0F1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusBadge(rented),
              const Spacer(),
              Flexible(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(car.plate, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: ink,
                        fontWeight: FontWeight.w800, letterSpacing: .4)),
              )),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: ink),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28),
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.onEdit?.call(car);
                    if (widget.onEdit == null) _comingSoon('Edit ${car.name}');
                  } else {
                    widget.onSchedule?.call(car);
                    if (widget.onSchedule == null) _comingSoon('Jadwal ${car.name}');
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Unit')),
                  PopupMenuItem(value: 'schedule', child: Text('Lihat Jadwal')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _carImage(car),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.15,
                          fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 3),
                  Text(car.colorName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: muted)),
                  const SizedBox(height: 5),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: _rupiah(car.dailyPrice),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                            color: blue)),
                    const TextSpan(text: ' / hari',
                        style: TextStyle(fontSize: 10, color: muted)),
                  ])),
                ],
              )),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 29,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(9)),
            child: Row(children: [
              _spec(Icons.airline_seat_recline_normal, '${car.seats} Kursi'),
              _spec(Icons.sports_esports_outlined, car.transmission),
              _spec(car.isHybrid ? Icons.bolt : Icons.local_gas_station_outlined, car.fuel),
            ]),
          ),
          const SizedBox(height: 8),
          if (rented) ...[
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const CircleAvatar(radius: 10, backgroundColor: Color(0xFF3263ED),
                    child: Icon(Icons.person_outline, color: Colors.white, size: 13)),
                const SizedBox(width: 6),
                Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penyewa: ${car.renter ?? '-'}', maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: blue, fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    Text(car.returnInfo ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 9)),
                  ],
                )),
                InkWell(
                  onTap: () => _comingSoon('Hubungi penyewa'),
                  child: const CircleAvatar(radius: 11, backgroundColor: Colors.white,
                      child: Icon(Icons.phone_outlined, color: blue, size: 13)),
                ),
              ]),
            ),
            const SizedBox(height: 6),
          ],
          Row(children: [
            Expanded(flex: 2, child: _actionButton(
                rented ? 'Detail Sewa' : 'Jadwal & Sewa',
                rented ? Icons.receipt_long_outlined : Icons.event_available_outlined,
                primary: !rented,
                onPressed: () {
                  if (rented) {
                    widget.onRentalDetail?.call(car);
                    if (widget.onRentalDetail == null) _comingSoon('Detail sewa ${car.name}');
                  } else {
                    widget.onSchedule?.call(car);
                    if (widget.onSchedule == null) _comingSoon('Jadwal ${car.name}');
                  }
                })),
            const SizedBox(width: 6),
            Expanded(child: _actionButton('Edit Unit', Icons.edit_outlined,
                onPressed: () {
                  widget.onEdit?.call(car);
                  if (widget.onEdit == null) _comingSoon('Edit ${car.name}');
                })),
          ]),
        ],
      ),
    );
  }

  Widget _statusBadge(bool rented) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: rented ? const Color(0xFFDDE7FF) : const Color(0xFFE0F7E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 3, backgroundColor: rented
              ? const Color(0xFF3263ED) : const Color(0xFF16A865)),
          const SizedBox(width: 5),
          Text(rented ? 'Sedang Disewa' : 'Tersedia',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: rented ? blue : const Color(0xFF168650))),
        ]),
      );

  Widget _carImage(ArmadaCar car) => Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 83, height: 61,
            child: car.imageAsset == null
                ? _imageFallback()
                : Image.asset(car.imageAsset!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback()),
          ),
        ),
        if (car.isHybrid)
          Positioned(top: 3, left: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF2769DE),
                  borderRadius: BorderRadius.circular(5)),
              child: const Text('HYBRID', style: TextStyle(color: Colors.white,
                  fontSize: 7, fontWeight: FontWeight.bold)),
            ),
          ),
        Positioned(right: 3, bottom: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xB9000000),
                  borderRadius: BorderRadius.circular(4)),
              child: Text('${car.year}', style: const TextStyle(
                  color: Colors.white, fontSize: 8)),
            )),
      ]);

  Widget _imageFallback() => Container(
        color: const Color(0xFFDDE4EC),
        child: const Icon(Icons.directions_car_filled_rounded,
            size: 36, color: Color(0xFF75869B)),
      );

  Widget _spec(IconData icon, String label) => Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: blue, size: 11),
          const SizedBox(width: 3),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: ink,
                  fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _actionButton(String label, IconData icon, {
    bool primary = false,
    required VoidCallback onPressed,
  }) => SizedBox(
        height: 33,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 13),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            elevation: 0,
            backgroundColor: primary ? blue : const Color(0xFFECEDEF),
            foregroundColor: primary ? Colors.white : const Color(0xFF303744),
            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
      );

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.directions_car_outlined, size: 44, color: muted),
          const SizedBox(height: 10),
          const Text('Armada tidak ditemukan',
              style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          TextButton(onPressed: () => setState(() {
            _searchController.clear();
            _filter = ArmadaFilter.all;
          }), child: const Text('Reset pencarian')),
        ]),
      );

  Widget _bottomNavigation() => Container(
        decoration: const BoxDecoration(color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEF0F4)))),
        padding: const EdgeInsets.fromLTRB(6, 7, 6, 5),
        child: Row(children: [
          _nav(0, 'Beranda', Icons.dashboard_outlined),
          _nav(1, 'Armada', Icons.directions_car_outlined),
          _nav(2, 'Pesanan', Icons.receipt_long_outlined, badge: 3),
          _nav(3, 'Bayar', Icons.account_balance_wallet_outlined, dot: true),
          _nav(4, 'Menu', Icons.grid_view_outlined),
        ]),
      );

  Widget _nav(int index, String label, IconData icon, {
    int? badge, bool dot = false,
  }) {
    final active = index == 1;
    return Expanded(child: InkWell(
      onTap: () {
        if (index == 1) return;
        if (widget.onNavTap != null) {
          widget.onNavTap!(index);
        } else {
          _comingSoon('Navigasi $label');
        }
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 22, child: Stack(clipBehavior: Clip.none, children: [
          Icon(icon, size: 21, color: active ? blue : const Color(0xFF565F72)),
          if (badge != null) Positioned(right: -7, top: -4,
              child: CircleAvatar(radius: 7, backgroundColor: const Color(0xFFE72C38),
                  child: Text('$badge', style: const TextStyle(
                      fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)))),
          if (dot) const Positioned(right: -3, top: -2,
              child: CircleAvatar(radius: 3, backgroundColor: Color(0xFF3263ED))),
        ])),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: active ? blue : const Color(0xFF565F72))),
      ]),
    ));
  }

  static String _rupiah(int amount) {
    final raw = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return 'Rp$buffer';
  }
}
