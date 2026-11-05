import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

const blue = Color(0xFF0755C9);
const muted = Color(0xFF697184);

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const blue = Color(0xFF0755C9);
  static const ink = Color(0xFF182238);
  static const muted = Color(0xFF697184);
  static const surface = Color(0xFFF8F9FE);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
            // Keep compact tablets in the two-column mobile layout; wider
            // tablets and iPads get the roomy dashboard treatment.
            final isTablet = constraints.maxWidth >= 700;
            final contentWidth = constraints.maxWidth > 960 ? 920.0 : constraints.maxWidth - (isTablet ? 64.0 : 56.0);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isTablet ? 32 : 28, 12, isTablet ? 32 : 28, 20),
              child: Center(child: SizedBox(width: contentWidth, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _greeting(), const SizedBox(height: 16),
                _statGrid(isTablet: isTablet), const SizedBox(height: 26), _fleetCard(), const SizedBox(height: 32),
                _sectionTitle('Aksi Cepat', 'Operasional Harian'), const SizedBox(height: 12), _quickActions(),
                const SizedBox(height: 28), _sectionTitle('Pengajuan Terbaru', 'Lihat Semua', dot: true), const SizedBox(height: 10),
                _requestGrid(isTablet: isTablet, width: contentWidth),
              ]))),
            );
          });
  }

  Widget _topBar(BuildContext context) => Row(children: [
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('NOV RENT', style: TextStyle(color: blue, fontSize: 15, fontWeight: FontWeight.w800)),
      Text('ADMIN HUB • DASHBOARD', style: TextStyle(color: muted, fontSize: 10, letterSpacing: .7)),
    ])),
    Stack(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: ink, size: 25)), Positioned(right: 7, top: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))]),
    PopupMenuButton<String>(onSelected: (value) async { if (value == 'logout') { await context.read<AuthProvider>().logout(); if (context.mounted) context.go('/login'); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Keluar'))], child: const CircleAvatar(radius: 18, backgroundColor: Color(0xFFD9E3F8), child: Icon(Icons.person, color: blue))),
  ]);

  Widget _greeting() => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text('Halo, Arya!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)), SizedBox(width: 9), Text('👋', style: TextStyle(fontSize: 18))]),
    SizedBox(height: 6), Row(children: [Icon(Icons.storefront_outlined, size: 16, color: blue), SizedBox(width: 6), Text('Cabang Surabaya - Juanda', style: TextStyle(color: muted, fontSize: 13))]),
  ]);

  Widget _statGrid({bool isTablet = false}) => GridView.count(crossAxisCount: isTablet ? 4 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: isTablet ? 1.25 : 1.58, children: [
    _stat('Pendapatan', 'Rp 3.85M', '+14%', Icons.payments_outlined, blue), _stat('Unit Aktif', '18', '/ 24', Icons.key_outlined, blue, progress: true),
    _stat('Pesanan', '4', 'Baru', Icons.inbox_outlined, Colors.orange), _stat('Verifikasi', '6', 'Antrean', Icons.gpp_bad_outlined, Colors.redAccent),
  ]);

  Widget _stat(String label, String value, String suffix, IconData icon, Color accent, {bool progress = false}) => Container(padding: const EdgeInsets.fromLTRB(12, 12, 12, 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: muted))), Icon(icon, size: 18, color: accent)]), const Spacer(),
    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)), const SizedBox(width: 5), Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(suffix, style: TextStyle(fontSize: 11, color: (suffix == 'Baru' || suffix == 'Antrean') ? accent : muted, fontWeight: FontWeight.w700)))]),
    if (progress) ...[const SizedBox(height: 9), ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(value: .75, minHeight: 5, backgroundColor: Color(0xFFDDE5FB), color: blue))],
  ]));

  Widget _fleetCard() => Container(padding: const EdgeInsets.fromLTRB(16, 17, 16, 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(children: [
    Row(children: [const Icon(Icons.pie_chart_outline, color: blue), const SizedBox(width: 8), const Expanded(child: Text('Ketersediaan Armada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink))), const Text('12 Total Mobil', style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600))]),
    const SizedBox(height: 16), ClipRRect(borderRadius: BorderRadius.circular(8), child: const Row(children: [Expanded(flex: 58, child: SizedBox(height: 8, child: ColoredBox(color: blue))), Expanded(flex: 33, child: SizedBox(height: 8, child: ColoredBox(color: Color(0xFF2347AE)))), Expanded(flex: 9, child: SizedBox(height: 8, child: ColoredBox(color: Color(0xFF777C89))))])),
    const SizedBox(height: 15), Row(children: [_fleetLegend('Tersedia', '58%', '(7)', blue), const SizedBox(width: 8), _fleetLegend('Disewa', '33%', '(4)', Color(0xFF2347AE)), const SizedBox(width: 8), _fleetLegend('Servis', '9%', '(1)', Color(0xFF777C89))]),
  ]));

  Widget _fleetLegend(String title, String percent, String count, Color color) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: const Color(0xFFF1F2F5), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text('● $title', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(percent, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)), Text(count, style: const TextStyle(fontSize: 9, color: muted))])));

  Widget _sectionTitle(String title, String action, {bool dot = false}) => Row(children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)), if (dot) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.circle, size: 8, color: Colors.red)), const Spacer(), Text(action, style: const TextStyle(fontSize: 11, color: blue, fontWeight: FontWeight.w600))]);

  Widget _quickActions() => Row(children: [_quick('Periksa\nPesanan', Icons.format_list_bulleted_rounded), _quick('Verifikasi\nBayar', Icons.mark_email_read_outlined), _quick('Tambah\nArmada', Icons.add_circle_outline, dark: false), _quick('Serah\nTerima', Icons.key_outlined, dark: false)]);

  Widget _quick(String label, IconData icon, {bool dark = true}) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: Column(children: [CircleAvatar(radius: 21, backgroundColor: dark ? const Color(0xFFE3EAFF) : const Color(0xFFECEEF1), child: Icon(icon, color: dark ? blue : const Color(0xFF4D5565), size: 21)), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.15, fontWeight: FontWeight.w700, color: ink))])));

  Widget _requestGrid({required bool isTablet, required double width}) {
    final cards = [
      _requestCard('#NOV-261024-001', 'Menunggu Konfirmasi', 'Toyota Avanza 1.5 G', 'Dimas Pratama', 'Dengan Sopir (Pak Joko)', '24 - 26 Okt 2026 (3 Hari)', 'Rp 1.125.000', 'Periksa Pengajuan', const Color(0xFFFFF5DD), highlighted: true),
      _requestCard('#NOV-261024-004', 'Menunggu Verifikasi Bayar', 'Mitsubishi Xpander Ultimate', 'Siti Rahma', 'Lepas Kunci', '25 - 27 Okt 2026 (2 Hari)', 'Rp 950.000', 'Cek Bukti Bayar', const Color(0xFFE6F8F1)),
      _requestCard('#NOV-261024-004', 'Kembali Hari Ini', 'Mitsubishi Xpander', 'Budi Suherman', 'Lepas Kunci', '21 - 25 Okt 2026 (4 jam lagi)', '', 'Periksa Kondisi', const Color(0xFFE3E8FF)),
    ];
    if (!isTablet) return Column(children: cards);
    return Wrap(spacing: 14, runSpacing: 0, children: cards.map((card) => SizedBox(width: (width - 14) / 2, child: card)).toList());
  }

  Widget _requestCard(String code, String status, String car, String customer, String detail, String period, String value, String action, Color color, {bool highlighted = false}) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.fromLTRB(12, 12, 12, 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text(code, style: const TextStyle(color: blue, fontWeight: FontWeight.w800, fontSize: 14)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)), child: Text(status, style: TextStyle(fontSize: 10, color: highlighted ? const Color(0xFF9A5700) : const Color(0xFF16715A), fontWeight: FontWeight.w700)))]),
    const SizedBox(height: 12), Row(children: [_carPlaceholder(), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(car, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink)), Text('Pemesan: $customer', style: const TextStyle(fontSize: 12, color: ink)), Text(detail, style: const TextStyle(fontSize: 11, color: blue))]))]),
    const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF0F2FD), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Text('Periode Sewa', style: TextStyle(fontSize: 11, color: muted)), const Spacer(), Flexible(child: Text(period, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w600))), if (value.isNotEmpty) ...[const SizedBox(width: 7), Text(value, style: const TextStyle(fontSize: 16, color: blue, fontWeight: FontWeight.w800))]])),
    const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {}, icon: Icon(highlighted ? Icons.receipt_long_outlined : Icons.fact_check_outlined, size: 16), label: Text(action), style: ElevatedButton.styleFrom(backgroundColor: highlighted ? blue : const Color(0xFFE6EAFE), foregroundColor: highlighted ? Colors.white : blue, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), textStyle: const TextStyle(fontWeight: FontWeight.w700)))),
  ]));

  Widget _carPlaceholder() => Container(width: 80, height: 62, decoration: BoxDecoration(color: const Color(0xFFDCE2E7), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.directions_car_filled_outlined, size: 42, color: Color(0xFF71808D)));

  Widget _bottomNavigation(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
    decoration: const BoxDecoration(
      color: Colors.white,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _nav(
          context,
          'Beranda',
          Icons.dashboard_outlined,
          active: true,
        ),
        _nav(
          context,
          'Armada',
          Icons.directions_car_outlined,
        ),
        _nav(
          context,
          'Pesanan',
          Icons.assignment_outlined,
        ),
        _nav(
          context,
          'Bayar',
          Icons.payments_outlined,
        ),
        _nav(
          context,
          'Menu',
          Icons.grid_view_outlined,
        ),
      ],
    ),
  );

Widget _nav(
  BuildContext context,
  String label,
  IconData icon, {
  bool active = false,
}) =>
    InkWell(
      onTap: () {
        switch (label) {
          case 'Beranda':
            context.go('/admin');
            break;

          case 'Armada':
            context.go('/admin/armada');
            break;

          case 'Pesanan':
            // TODO: Route pesanan admin
            break;

          case 'Bayar':
            // TODO: Route pembayaran admin
            break;

          case 'Menu':
            // TODO: Route menu admin
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: active ? blue : muted,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? blue : muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
}
