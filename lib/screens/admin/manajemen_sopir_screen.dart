import 'package:flutter/material.dart';
import 'edit_sopir_screen.dart';
import 'tambah_sopir_screen.dart';

// UI Manajemen Sopir NOV Rent. Data masih contoh, belum terhubung Firestore.
class ManajemenSopirScreen extends StatefulWidget {
  const ManajemenSopirScreen({super.key});

  @override
  State<ManajemenSopirScreen> createState() => _ManajemenSopirScreenState();
}

class _ManajemenSopirScreenState extends State<ManajemenSopirScreen> {
  static const blue = Color(0xFF0755C9);
  static const ink = Color(0xFF182238);
  static const muted = Color(0xFF697184);
  static const background = Color(0xFFF8F9FE);
  static const green = Color(0xFF008965);

  String filter = 'Semua';

  // Contoh data agar UI dapat dipreview sebelum CRUD diimplementasikan.
  List<_DriverView> drivers = const [
    _DriverView(
      name: 'Pak Hendra Wijaya', initials: 'HW', rating: '4.9', trips: 148,
      busy: true, car: 'Mitsubishi Xpander', plate: 'L 1892 NM',
      transmission: 'Matic', route: 'Surabaya → Sidoarjo',
      customer: 'Budi Santoso',
    ),
    _DriverView(
      name: 'Mas Dian Pratama', initials: 'DP', rating: '4.85', trips: 92,
      busy: false, car: 'Toyota Innova Zenix', plate: 'W 1042 QP',
      transmission: 'Hybrid', route: 'Pool Hub Juanda Terminal 1',
      customer: '',
    ),
  ];

  Future<void> openEditDriver(_DriverView driver) async {
    final result = await Navigator.of(context).push<EditSopirResult>(
      MaterialPageRoute(
        builder: (_) => EditSopirScreen(
          name: driver.name,
          initials: driver.initials,
          car: driver.car,
          plate: driver.plate,
          carId: driver.carId,
          busy: driver.busy,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.deleted) {
        drivers = drivers.where((d) => !identical(d, driver)).toList();
      } else {
        drivers = drivers.map((d) => identical(d, driver)
            ? _DriverView(
          name: result.name,
          initials: d.initials,
          rating: d.rating,
          trips: d.trips,
          busy: result.status == 'Bertugas',
          car: result.car,
          plate: result.plate,
          carId: result.carId,
          transmission: d.transmission,
          route: d.route,
          customer: d.customer,
        )
            : d).toList();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.deleted
          ? 'Sopir dihapus dari data contoh (belum Firestore).'
          : 'Perubahan ditampilkan sementara (belum Firestore).'),
    ));
  }

  Future<void> openTambahDriver() async {
    final result = await Navigator.of(context).push<TambahSopirResult>(
      MaterialPageRoute(builder: (_) => const TambahSopirScreen()),
    );
    if (!mounted || result == null) return;
    final initials = result.name.trim().split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    setState(() {
      drivers = [
        _DriverView(
          name: result.name,
          initials: initials,
          rating: '-',
          trips: 0,
          busy: false,
          car: result.car.isEmpty ? 'Belum ada armada' : result.car,
          plate: result.plate,
          carId: result.carId,
          transmission: 'Belum ditentukan',
          route: result.car.isEmpty ? 'On-Call / Standby Pool' : 'Siap penugasan',
          customer: '',
        ),
        ...drivers,
      ];
      filter = 'Semua';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(
        'Sopir ditambahkan ke daftar sementara (belum Firestore).',
      )),
    );
  }

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature akan diaktifkan saat CRUD dibuat.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = drivers.where((d) {
      if (filter == 'Bertugas') return d.busy;
      if (filter == 'Siap Jalan') return !d.busy;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: background,
      // Header dan navbar bawah sudah dibuat oleh AdminShell.
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _introCard(),
          const SizedBox(height: 24),
          _filters(),
          const SizedBox(height: 29),
          _sectionHeader('Status Pengemudi Aktif', 'Live Dispatch'),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(28),
              child: Text('Tidak ada sopir pada kategori ini.'),
            )),
          ...visible.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _driverCard(d),
          )),
          const SizedBox(height: 19),
          const Text('Laporan Kinerja Minggu Ini', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: ink,
          )),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _metricCard(
              'JAM KEMUDI', '42', 'Jam', '+14% beban stabil',
              Icons.schedule, blue, green,
            )),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(
              'KEPUASAN TAMU', '98%', 'Puas', 'Dari 64 ulasan tamu',
              Icons.sentiment_satisfied_alt_outlined, green, green,
            )),
          ]),
          const SizedBox(height: 12),
          _cashCard(),
          const SizedBox(height: 29),
          _sectionHeader('Jadwal Pendampingan Tamu Hari Ini', '2 Rute Berjalan'),
          const SizedBox(height: 14),
          _scheduleCard(),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 49, child: ElevatedButton.icon(
            onPressed: openTambahDriver,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Tambah Sopir Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 47, child: OutlinedButton.icon(
            onPressed: () => showComingSoon('Unduh laporan'),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Unduh Laporan Operasional (PDF / XLSX)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              side: const BorderSide(color: Color(0xFFDCE4F2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
          const SizedBox(height: 8),
          const Text('Data tampilan contoh, belum terhubung ke Firestore.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: muted)),
        ],
      ),
    );
  }

  Widget _introCard() => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF4FF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD8E6FF)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pill('●  OPERASIONAL REAL-TIME', blue, Colors.white),
      const SizedBox(height: 14),
      const Text('✓  12 Mitra Terverifikasi', style: TextStyle(color: muted, fontSize: 13)),
      const SizedBox(height: 13),
      const Text('Pantau & Alokasi Driver', style: TextStyle(
        color: ink, fontWeight: FontWeight.w800, fontSize: 20,
      )),
      const SizedBox(height: 6),
      const Text('Kendali mobilitas armada, rute aktif, dan uang jalan operasional NOV RENT.',
          style: TextStyle(color: muted, height: 1.5, fontSize: 13)),
    ]),
  );

  Widget _filters() => Row(children: [
    _filterButton('Semua', '12'),
    const SizedBox(width: 7),
    _filterButton('Bertugas', '8'),
    const SizedBox(width: 7),
    _filterButton('Siap Jalan', '4'),
  ]);

  Widget _filterButton(String name, String count) {
    final selected = filter == name;
    return Expanded(child: InkWell(
      onTap: () => setState(() => filter = name),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? blue : const Color(0xFFE8EFFB),
          borderRadius: BorderRadius.circular(25),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Row(children: [
          if (!selected) Icon(Icons.circle, size: 9,
              color: name == 'Siap Jalan' ? green : blue),
          if (!selected) const SizedBox(width: 5),
          Text(name, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : ink)),
          const SizedBox(width: 6),
          Text(count, style: TextStyle(fontSize: 11,
              color: selected ? Colors.white70 : muted)),
        ])),
      ),
    ));
  }

  Widget _sectionHeader(String heading, String extra) => Row(children: [
    Expanded(child: Text(heading, style: const TextStyle(
      fontSize: 16, fontWeight: FontWeight.w800, color: ink,
    ))),
    Text(extra, style: const TextStyle(fontSize: 10,
        color: blue, fontWeight: FontWeight.w600)),
  ]);

  // Kartu sopir aktif sesuai desain terbaru.
  Widget _driverCard(_DriverView d) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        InkWell(
          onTap: () => openEditDriver(d),
          borderRadius: BorderRadius.circular(30),
          child: Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFDCE9FF),
              child: Text(d.initials,
                  style: const TextStyle(color: blue, fontWeight: FontWeight.bold)),
            ),
            Positioned(
              bottom: 0, right: -1,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: d.busy ? blue : green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 11),
        Expanded(child: InkWell(
          onTap: () => openEditDriver(d),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(d.name, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ink, fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
        )),
        const SizedBox(width: 5),
        _pill(d.busy ? '● Sedang Bertugas' : '● Siap Jalan',
            d.busy ? blue : green,
            d.busy ? const Color(0xFFEAF2FF) : const Color(0xFFE4F7F0)),
      ]),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3FC),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.directions_car_outlined, size: 17, color: ink),
            const SizedBox(width: 5),
            Expanded(child: Text(d.car, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: ink))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FC),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(d.plate, style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: ink)),
            ),
            const SizedBox(width: 6),
            Text(d.transmission,
                style: const TextStyle(fontSize: 10, color: muted)),
          ]),
          const SizedBox(height: 10),
          if (d.busy)
            Row(children: [
              const Icon(Icons.radio_button_checked, color: blue, size: 15),
              const SizedBox(width: 4),
              const Text('Surabaya', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: ink)),
              const SizedBox(width: 7),
              const Expanded(child: Row(children: [
                Expanded(child: Divider(color: Color(0xFFD3DDF2))),
                Icon(Icons.arrow_forward, size: 14, color: blue),
                Expanded(child: Divider(color: Color(0xFFD3DDF2))),
              ])),
              const SizedBox(width: 7),
              const Icon(Icons.location_on_outlined, size: 15, color: green),
              const SizedBox(width: 2),
              const Text('Sidoarjo', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: green)),
            ])
          else
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 15, color: green),
              const SizedBox(width: 4),
              Expanded(child: Text('Standby di: ${d.route}',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: ink))),
            ]),
        ]),
      ),
      const SizedBox(height: 12),
      if (d.busy)
        Row(children: [
          const Icon(Icons.badge_outlined, color: muted, size: 16),
          const SizedBox(width: 5),
          Expanded(child: Text('Tamu: ${d.customer}',
              style: const TextStyle(fontSize: 11, color: ink))),
          _roundAction(Icons.call_outlined, 'Telepon sopir'),
          const SizedBox(width: 8),
          _roundAction(Icons.near_me_outlined, 'Navigasi rute'),
        ])
      else
        Row(children: [
          const Icon(Icons.access_time, size: 16, color: green),
          const SizedBox(width: 4),
          const Expanded(child: Text('Tersedia untuk order mendesak',
              style: TextStyle(fontSize: 11, color: green))),
          SizedBox(height: 34, child: ElevatedButton(
            onPressed: () => showComingSoon('Penugasan sopir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
            child: const Text('Tugaskan ›', style: TextStyle(fontSize: 11)),
          )),
        ]),
    ]),
  );

  Widget _roundAction(IconData icon, String title) => Material(
    color: const Color(0xFFE9EEFF),
    shape: const CircleBorder(),
    child: IconButton(
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(7),
      icon: Icon(icon, color: blue, size: 18),
      onPressed: () => showComingSoon(title),
    ),
  );

  Widget _metricCard(String label, String value, String unit, String detail,
      IconData icon, Color iconColor, Color detailColor) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(
            fontSize: 10, color: muted, fontWeight: FontWeight.bold))),
        Icon(icon, size: 18, color: iconColor),
      ]),
      const SizedBox(height: 13),
      RichText(text: TextSpan(children: [
        TextSpan(text: '$value ', style: const TextStyle(
            fontSize: 22, color: ink, fontWeight: FontWeight.w800)),
        TextSpan(text: unit, style: const TextStyle(fontSize: 11, color: green)),
      ])),
      const SizedBox(height: 9),
      Text(detail, style: TextStyle(fontSize: 10, color: detailColor)),
    ]),
  );

  Widget _cashCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(15)),
    child: Row(children: [
      const CircleAvatar(backgroundColor: Color(0xFFE5F0FF),
          child: Icon(Icons.payments_outlined, color: blue)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KAS OPERASIONAL & UANG JALAN', style: TextStyle(
                fontSize: 10, color: muted, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('Rp 450.000', style: TextStyle(
                fontSize: 18, color: ink, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Bensin, tol & parkir disetujui',
                style: TextStyle(fontSize: 10, color: muted)),
          ])),
      _pill('✓ Cair', green, const Color(0xFFE4F7F0)),
    ]),
  );

  Widget _scheduleCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(15)),
    child: const Column(children: [
      _ScheduleRow('BS', 'Budi Santoso', '08:00 – 18:00',
          'Surabaya City Tour (House of Sampoerna • Tunjungan Plaza)',
          'Driver pendamping: Hendra Wijaya'),
      Divider(height: 29, color: Color(0xFFE8EAF0)),
      _ScheduleRow('SM', 'Sarah Melinda', 'Standby 14:30',
          'Penjemputan Bandara Juanda T2 → Hotel Majapahit',
          'Konfirmasi penerbangan tepat waktu'),
    ]),
  );

  Widget _pill(String value, Color foreground, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(value, style: TextStyle(fontSize: 10,
        color: foreground, fontWeight: FontWeight.w700)),
  );
}

class _DriverView {
  final String name, initials, rating, car, plate, transmission, route, customer;
  final int trips;
  final bool busy;
  final String carId;
  const _DriverView({required this.name, required this.initials,
    required this.rating, required this.trips, required this.busy,
    required this.car, required this.plate, this.carId = '',
    required this.transmission, required this.route, required this.customer});
}

class _ScheduleRow extends StatelessWidget {
  final String initials, name, time, location, detail;
  const _ScheduleRow(this.initials, this.name, this.time, this.location, this.detail);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFDCEBFF),
        child: Text(initials, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold,
            color: Color(0xFF0755C9))),
      ),
      const SizedBox(width: 11),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800, color: Color(0xFF182238)))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: time.startsWith('Standby')
                    ? const Color(0xFFE7F8F0) : const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(time, textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: time.startsWith('Standby')
                          ? const Color(0xFF008965) : const Color(0xFF0755C9))),
            ),
          ]),
          const SizedBox(height: 7),
          Text(location, style: const TextStyle(
              fontSize: 11, color: Color(0xFF697184), height: 1.4)),
          const SizedBox(height: 5),
          Text(detail, style: const TextStyle(
              fontSize: 10, color: Color(0xFF8C9BB5))),
        ],
      )),
    ],
  );
}
