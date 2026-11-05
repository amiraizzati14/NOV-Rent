import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan provider proyek untuk sesi dan logout.
    final auth = context.watch<AuthProvider>();
    void pending(String label) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label belum tersedia.')),
      );
    }

    return _AccountView(
      // Ganti data contoh ini dengan data pengguna dari provider/model proyek.
      name: 'Ahmad Rizky Pratama',
      phone: '+62 812-3456-7890',
      email: 'ahmad.rizky@email.com',
      showBottomNavigation: false,
      onEdit: () => pending('Ubah profil'),
      onSearch: () => pending('Pencarian'),
      onFilter: () => pending('Filter'),
      onNotifications: () => pending('Notifikasi'),
      onHelp: () => pending('Pusat bantuan'),
      onTerms: () => pending('Syarat dan ketentuan'),
      onPrivacy: () => pending('Kebijakan privasi'),
      onLogout: () async {
        try {
          await auth.logout();
          if (context.mounted) context.go('/login');
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal keluar. Silakan coba lagi.')),
            );
          }
        }
      },
    );
  }
}


/// UI profil NOV Rent. Hubungkan callback ke router dan autentikasi proyek.
/// showBottomNavigation: false jika halaman berada di MainShell.
class _AccountView extends StatelessWidget {
  const _AccountView({
    super.key,
    this.name = 'Ahmad Rizky Pratama',
    this.phone = '+62 812-3456-7890',
    this.email = 'ahmad.rizky@email.com',
    this.avatar,
    this.totalRentals = 5,
    this.activeRentals = 1,
    this.coupons = 2,
    this.verified = true,
    this.showBottomNavigation = true,
    this.onEdit,
    this.onSearch,
    this.onFilter,
    this.onNotifications,
    this.onHelp,
    this.onTerms,
    this.onPrivacy,
    this.onLogout,
    this.onNavigation,
  });

  final String name, phone, email;
  final ImageProvider? avatar;
  final int totalRentals, activeRentals, coupons;
  final bool verified, showBottomNavigation;
  final VoidCallback? onEdit, onSearch, onFilter, onNotifications;
  final VoidCallback? onHelp, onTerms, onPrivacy, onLogout;
  final ValueChanged<int>? onNavigation;

  static const _blue = Color(0xFF005BCB);
  static const _ink = Color(0xFF202126);
  static const _muted = Color(0xFF74798D);
  static const _background = Color(0xFFF9F8FE);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _background,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Roboto', bodyColor: _ink, displayColor: _ink,
        ),
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _header(),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _profile(),
                    const SizedBox(height: 16),
                    Row(children: [
                      _stat(Icons.badge_outlined, '$totalRentals', 'Total Sewa',
                          const Color(0xFFDCE4F2), const Color(0xFF667184)),
                      const SizedBox(width: 9),
                      _stat(Icons.key_outlined, '$activeRentals', 'Sewa Aktif',
                          const Color(0xFFDCE6FF), _blue, dot: true),
                      const SizedBox(width: 9),
                      _stat(Icons.confirmation_number_outlined, '$coupons',
                          'Kupon Promo', const Color(0xFFFFDCC8),
                          const Color(0xFF963C0C)),
                    ]),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text('BANTUAN & KETENTUAN', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          letterSpacing: 1.1, color: _muted)),
                    ),
                    _card(Column(children: [
                      _menu(Icons.support_agent, 'Pusat Bantuan & CS 24/7',
                          onHelp, subtitle: 'Respon cepat via WhatsApp & Panggilan',
                          online: true),
                      _menu(Icons.description_outlined,
                          'Syarat & Ketentuan Sewa', onTerms),
                      _menu(Icons.policy_outlined, 'Kebijakan Privasi', onPrivacy),
                    ])),
                    const SizedBox(height: 20),
                    _card(_menu(Icons.logout, 'Keluar dari Akun',
                        onLogout == null ? null : () => _confirmLogout(context),
                        danger: true)),
                    const SizedBox(height: 22),
                    const Text('NOV RENT • Armada Terbaik & Terpercaya',
                        textAlign: TextAlign.center, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: Color(0xFF474D5E))),
                    const SizedBox(height: 5),
                    const Text('Versi Aplikasi 2.4.0 (Build 418)',
                        textAlign: TextAlign.center, style: TextStyle(
                            fontSize: 11, letterSpacing: .3, color: _muted)),
                  ],
                ),
              )),
            )),
          ]),
        ),
        bottomNavigationBar: showBottomNavigation ? _navigation() : null,
      ),
    );
  }

  Widget _header() => SizedBox(height: 66, child: Padding(
    padding: const EdgeInsets.only(left: 20, right: 12),
    child: Row(children: [
      const Expanded(child: Text('Riwayat Sewa', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.5))),
      IconButton(onPressed: onSearch, icon: const Icon(Icons.search),
          color: const Color(0xFF474D5E), disabledColor: const Color(0xFF474D5E),
          constraints: const BoxConstraints.tightFor(width: 44)),
      IconButton(onPressed: onFilter, icon: const Icon(Icons.tune, size: 21),
          color: const Color(0xFF474D5E), disabledColor: const Color(0xFF474D5E),
          constraints: const BoxConstraints.tightFor(width: 44)),
      IconButton(onPressed: onNotifications,
          constraints: const BoxConstraints.tightFor(width: 44),
          icon: Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.notifications_none, color: Color(0xFF474D5E)),
            Positioned(right: 0, top: -1, child: Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF1675EE),
                    shape: BoxShape.circle))),
          ])),
      const SizedBox(width: 3),
      const CircleAvatar(radius: 16, backgroundColor: _blue,
          child: Icon(Icons.person_outline, size: 19, color: Colors.white)),
      const SizedBox(width: 8),
    ]),
  ));

  Widget _profile() => _card(Padding(
    padding: const EdgeInsets.fromLTRB(12, 14, 8, 16),
    child: Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 68, height: 68,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Color(0xFFF5F7F8),
                shape: BoxShape.circle),
            child: CircleAvatar(backgroundImage: avatar,
                backgroundColor: const Color(0xFFE1E8EE),
                child: avatar == null ? const Icon(Icons.person,
                    color: Color(0xFF65768B), size: 38) : null)),
        const SizedBox(width: 12),
        Expanded(child: Padding(padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(name, style: const TextStyle(
                    fontSize: 18, height: 1.15, fontWeight: FontWeight.w700))),
                const SizedBox(width: 4),
                Material(color: const Color(0xFFF4F5FB),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(onTap: onEdit,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(padding: EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.edit_outlined, size: 14, color: _blue),
                              SizedBox(width: 3),
                              Text('Ubah', style: TextStyle(fontSize: 12, color: _blue)),
                            ])))),
              ]),
              const SizedBox(height: 3),
              Text(phone, style: const TextStyle(fontSize: 14,
                  color: Color(0xFF474D5E))),
              const SizedBox(height: 3),
              Text(email, style: const TextStyle(fontSize: 11,
                  color: _muted, letterSpacing: .3)),
            ]))),
      ]),
      const SizedBox(height: 8),
      Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(verified ? Icons.verified_user : Icons.shield_outlined,
                color: _blue, size: 17),
            const SizedBox(width: 4),
            Expanded(child: Text(verified ? 'Terverifikasi KTP & SIM A'
                : 'KTP & SIM A belum terverifikasi',
                style: const TextStyle(fontSize: 12))),
            Text(verified ? 'Aktif' : 'Menunggu', style: const TextStyle(
                color: _blue, fontSize: 11)),
          ])),
    ]),
  ));

  Widget _stat(IconData icon, String value, String label, Color bg, Color fg,
      {bool dot = false}) => Expanded(child: _card(Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(children: [
      CircleAvatar(radius: 16, backgroundColor: bg,
          child: Icon(icon, size: 19, color: fg)),
      const SizedBox(height: 7),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (dot) ...[
          Container(width: 6, height: 6, decoration: const BoxDecoration(
              shape: BoxShape.circle, color: _blue)),
          const SizedBox(width: 4),
        ],
        Text(value, style: const TextStyle(fontSize: 19,
            height: 1, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11,
          color: Color(0xFF3D4455), letterSpacing: .3)),
    ]),
  )));

  Widget _menu(IconData icon, String title, VoidCallback? tap,
      {String? subtitle, bool online = false, bool danger = false}) {
    final color = danger ? const Color(0xFFE00000) : _ink;
    return Material(color: Colors.transparent, child: InkWell(
      onTap: tap, borderRadius: BorderRadius.circular(14),
      child: Padding(padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 12),
          child: Row(children: [
            CircleAvatar(radius: 18,
                backgroundColor: danger ? const Color(0xFFFFEFED)
                    : const Color(0xFFF3F4F8),
                child: Icon(icon, size: 20,
                    color: danger ? color : const Color(0xFF4A5163))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6,
                      children: [
                        Text(title, style: TextStyle(fontSize: 14, color: color,
                            fontWeight: FontWeight.w500)),
                        if (online) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFFE8F0FF),
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text('Online', style: TextStyle(
                                color: _blue, fontSize: 10))),
                      ]),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11,
                        letterSpacing: .2, color: Color(0xFF4A5163))),
                  ],
                ])),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20,
                color: danger ? const Color(0xFFEB6B6B) : _muted),
          ])),
    ));
  }

  Widget _card(Widget child) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x080D1330),
            offset: Offset(0, 1), blurRadius: 1)]),
    child: child,
  );

  Widget _navigation() => Container(
    decoration: const BoxDecoration(color: Color(0xFFF8F7FE),
        boxShadow: [BoxShadow(color: Color(0x080D1330),
            blurRadius: 12, offset: Offset(0, -4))]),
    child: SafeArea(top: false, child: SizedBox(height: 64,
        child: Row(children: [
          _navItem(0, Icons.home_outlined, 'Beranda'),
          _navItem(1, Icons.receipt_long_outlined, 'Riwayat'),
          _navItem(2, Icons.directions_car_outlined, 'Armada'),
          _navItem(3, Icons.account_circle_outlined, 'Akun'),
        ]))),
  );

  Widget _navItem(int index, IconData icon, String label) => Expanded(
    child: InkWell(onTap: onNavigation == null ? null
        : () => onNavigation!(index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 23, color: const Color(0xFF474D5E)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12,
              color: Color(0xFF474D5E))),
        ])),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Keluar dari Akun?'),
          content: const Text('Kamu perlu masuk kembali untuk mengakses akun.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Keluar', style: TextStyle(color: Colors.red))),
          ],
        ));
    if (confirmed == true) onLogout?.call();
  }
}
