import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F8FE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 14),
              const Text('Silakan login untuk melihat profil akun Anda.'),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login Sekarang'),
              ),
            ],
          ),
        ),
      );
    }

    final String userId = currentUser.uid;
    final String defaultName = currentUser.displayName ?? 'Pengguna';
    final String defaultEmail = currentUser.email ?? '-';

    void pending(String label) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label belum tersedia.')),
      );
    }

    // Stream profil user dari Firestore
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? {};
        final String name = userData['name']?.toString() ?? defaultName;
        final String phone = userData['phone']?.toString() ?? '-';
        final String email = userData['email']?.toString() ?? defaultEmail;
        final String verificationStatus =
            (userData['verificationStatus'] as String?)?.toLowerCase() ??
                'unverified';
        final bool isVerified = verificationStatus == 'verified';

        // Stream pesanan user dari Firestore untuk hitung Total Sewa & Sewa Aktif
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, ordersSnapshot) {
            final orders = ordersSnapshot.data?.docs ?? [];
            final int totalRentals = orders.length;

            final int activeRentals = orders.where((doc) {
              final status =
                  doc.data()['paymentStatus']?.toString().toLowerCase() ??
                      doc.data()['orderStatus']?.toString().toLowerCase() ??
                      '';
              return status == 'aktif' ||
                  status == 'active' ||
                  status == 'confirmed' ||
                  status == 'lunas';
            }).length;

            return _AccountView(
              name: name,
              phone: phone,
              email: email,
              totalRentals: totalRentals,
              activeRentals: activeRentals,
              coupons: 0,
              verified: isVerified,
              verificationStatus: verificationStatus,
              showBottomNavigation: false,
              onEdit: () => pending('Ubah profil'),
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
                      const SnackBar(
                          content: Text('Gagal keluar. Silakan coba lagi.')),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}

/// UI profil NOV Rent. Hubungkan callback ke router dan autentikasi proyek.
class _AccountView extends StatelessWidget {
  const _AccountView({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    this.avatar,
    this.totalRentals = 0,
    this.activeRentals = 0,
    this.coupons = 0,
    this.verified = false,
    this.verificationStatus = 'unverified',
    this.showBottomNavigation = false,
    this.onEdit,
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
  final String verificationStatus;
  final VoidCallback? onEdit, onNotifications;
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
              fontFamily: 'Roboto',
              bodyColor: _ink,
              displayColor: _ink,
            ),
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _profile(),
                        const SizedBox(height: 16),
                        Row(children: [
                          _stat(
                              Icons.badge_outlined,
                              '$totalRentals',
                              'Total Sewa',
                              const Color(0xFFDCE4F2),
                              const Color(0xFF667184)),
                          const SizedBox(width: 9),
                          _stat(Icons.key_outlined, '$activeRentals',
                              'Sewa Aktif', const Color(0xFFDCE6FF), _blue,
                              dot: activeRentals > 0),
                          const SizedBox(width: 9),
                          _stat(
                              Icons.confirmation_number_outlined,
                              '$coupons',
                              'Kupon Promo',
                              const Color(0xFFFFDCC8),
                              const Color(0xFF963C0C)),
                        ]),
                        const SizedBox(height: 18),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text('BANTUAN & KETENTUAN',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                  color: _muted)),
                        ),
                        _card(Column(children: [
                          _menu(Icons.support_agent, 'Pusat Bantuan & CS 24/7',
                              onHelp,
                              subtitle: 'Respon cepat via WhatsApp & Panggilan',
                              online: true),
                          _menu(Icons.description_outlined,
                              'Syarat & Ketentuan Sewa', onTerms),
                          _menu(Icons.policy_outlined, 'Kebijakan Privasi',
                              onPrivacy),
                        ])),
                        const SizedBox(height: 20),
                        _card(_menu(
                            Icons.logout,
                            'Keluar dari Akun',
                            onLogout == null
                                ? null
                                : () => _confirmLogout(context),
                            danger: true)),
                        const SizedBox(height: 22),
                        const Text('NOV RENT • Armada Terbaik & Terpercaya',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF474D5E))),
                        const SizedBox(height: 5),
                        const Text('Versi Aplikasi 2.4.0 (Build 418)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: .3,
                                color: _muted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
        bottomNavigationBar: showBottomNavigation ? _navigation() : null,
      ),
    );
  }

  // Header: Judul "Profil", tombol search dan avatar bulat di atas navbar sudah dihapus
  Widget _header() => SizedBox(
        height: 66,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNotifications,
                constraints: const BoxConstraints.tightFor(width: 44),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none,
                        color: Color(0xFF474D5E)),
                    Positioned(
                      right: 0,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1675EE),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _profile() {
    final isPending = verificationStatus == 'pending';
    final isVerified = verified || verificationStatus == 'verified';

    return _card(Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7F8),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  backgroundImage: avatar,
                  backgroundColor: const Color(0xFFE1E8EE),
                  child: avatar == null
                      ? const Icon(Icons.person,
                          color: Color(0xFF65768B), size: 38)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: const Color(0xFFF4F5FB),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: onEdit,
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined,
                                        size: 13, color: _blue),
                                    SizedBox(width: 3),
                                    Text('Ubah',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: _blue,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(phone,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF474D5E))),
                      const SizedBox(height: 2),
                      Text(email,
                          style: const TextStyle(fontSize: 11, color: _muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isVerified
                  ? const Color(0xFFEEF3FF)
                  : (isPending
                      ? const Color(0xFFFFF7E6)
                      : const Color(0xFFF5F6F8)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified
                      ? Icons.verified_user
                      : (isPending
                          ? Icons.hourglass_top_rounded
                          : Icons.shield_outlined),
                  color: isVerified
                      ? _blue
                      : (isPending ? const Color(0xFFD46B08) : _muted),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isVerified
                        ? 'Terverifikasi KTP & SIM A'
                        : (isPending
                            ? 'Verifikasi Sedang Ditinjau'
                            : 'KTP & SIM A belum terverifikasi'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  isVerified ? 'Aktif' : (isPending ? 'Menunggu' : 'Belum'),
                  style: TextStyle(
                    color: isVerified
                        ? _blue
                        : (isPending ? const Color(0xFFD46B08) : _muted),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _stat(IconData icon, String value, String label, Color bg, Color fg,
          {bool dot = false}) =>
      Expanded(
        child: _card(Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              CircleAvatar(
                  radius: 16,
                  backgroundColor: bg,
                  child: Icon(icon, size: 19, color: fg)),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (dot) ...[
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: _blue)),
                    const SizedBox(width: 4),
                  ],
                  Text(value,
                      style: const TextStyle(
                          fontSize: 19,
                          height: 1,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3D4455),
                      letterSpacing: .3)),
            ],
          ),
        )),
      );

  Widget _menu(IconData icon, String title, VoidCallback? tap,
      {String? subtitle, bool online = false, bool danger = false}) {
    final color = danger ? const Color(0xFFE00000) : _ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    danger ? const Color(0xFFFFEFED) : const Color(0xFFF3F4F8),
                child: Icon(icon,
                    size: 20, color: danger ? color : const Color(0xFF4A5163)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 14,
                                color: color,
                                fontWeight: FontWeight.w500)),
                        if (online)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FF),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text('Online',
                                style: TextStyle(color: _blue, fontSize: 10)),
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: .2,
                              color: Color(0xFF4A5163))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 20, color: danger ? const Color(0xFFEB6B6B) : _muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x080D1330), offset: Offset(0, 1), blurRadius: 1)
          ],
        ),
        child: child,
      );

  Widget _navigation() => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F7FE),
          boxShadow: [
            BoxShadow(
                color: Color(0x080D1330), blurRadius: 12, offset: Offset(0, -4))
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _navItem(0, Icons.home_outlined, 'Beranda'),
                _navItem(1, Icons.receipt_long_outlined, 'Riwayat'),
                _navItem(2, Icons.directions_car_outlined, 'Armada'),
                _navItem(3, Icons.account_circle_outlined, 'Akun'),
              ],
            ),
          ),
        ),
      );

  Widget _navItem(int index, IconData icon, String label) => Expanded(
        child: InkWell(
          onTap: onNavigation == null ? null : () => onNavigation!(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: const Color(0xFF474D5E)),
              const SizedBox(height: 3),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF474D5E))),
            ],
          ),
        ),
      );

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Kamu perlu masuk kembali untuk mengakses akun.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) onLogout?.call();
  }
}
