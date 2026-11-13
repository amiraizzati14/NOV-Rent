
import 'package:flutter/material.dart';

class PesananAdminScreen extends StatefulWidget {
  const PesananAdminScreen({super.key});

  @override
  State<PesananAdminScreen> createState() =>
      _PesananAdminScreenState();
}

class _PesananAdminScreenState extends State<PesananAdminScreen> {
  static const Color primary = Color(0xFF0755C9);
  static const Color background = Color(0xFFF7F8FD);
  static const Color dark = Color(0xFF252B3B);
  static const Color muted = Color(0xFF777E91);

  int selectedTab = 0;
  int selectedNav = 2;
  DateTime selectedDate = DateTime(2025, 3, 15);

  final List<Map<String, dynamic>> orders = [
    {
      'id': 'NR-9042',
      'time': '10 mnt lalu',
      'status': 'Perlu Disetujui',
      'car': 'Toyota Avanza 1.5 G',
      'image': '',
      'service': 'Lepas Kunci',
      'duration': '2 Hari',
      'date': '15 Mar – 17 Mar 2025',
      'customer': 'Budi Santoso',
      'verified': true,
      'location': 'Bandara Juanda (SUB)',
      'price': 'Rp 800.000',
      'type': 'pending',
    },
    {
      'id': 'NR-9040',
      'time': 'Hari ke-1 dari 3',
      'status': 'Berjalan',
      'car': 'Mitsubishi Xpander',
      'image': '',
      'service': 'Dengan Sopir',
      'duration': 'Plat L 1892 NM',
      'date': 'Driver: Pak Hendra',
      'customer': 'Surabaya → Bromo',
      'verified': false,
      'location': 'On Route',
      'price': '',
      'type': 'active',
    },
    {
      'id': 'NR-9038',
      'time': 'Sarah Melinda',
      'status': 'Kembali Hari Ini',
      'car': 'Honda HR-V 1.5 SE',
      'image': '',
      'service': 'Lepas Kunci',
      'duration': 'Plat W 1402 EF',
      'date': 'Batas: 20:00 (Sisa 3 Jam)',
      'customer': 'Pool Surabaya',
      'verified': false,
      'location': 'Inspeksi Pengembalian',
      'price': '',
      'type': 'return',
    },
  ];

  List<Map<String, dynamic>> get filteredOrders {
    if (selectedTab == 0) {
      return orders.where((o) => o['type'] == 'pending').toList();
    } else if (selectedTab == 1) {
      return orders.where((o) => o['type'] == 'active').toList();
    } else {
      return orders.where((o) => o['type'] == 'finished').toList();
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyOrder(Map<String, dynamic> order) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verifikasi Pengajuan'),
        content: Text(
          'Apakah kamu ingin menyetujui pengajuan '
              '${order['id']} atas nama ${order['customer']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, 'approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (result == 'approve') {
      setState(() {
        order['type'] = 'active';
        order['status'] = 'Berjalan';
      });
      _showMessage('Pengajuan berhasil disetujui (simulasi).');
    }
  }

  Future<void> _rejectOrder(Map<String, dynamic> order) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesanan ${order['id']}'),
            const SizedBox(height: 12),
            const Text('Masukkan alasan penolakan:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Foto SIM kurang jelas.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak Pengajuan'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason != null) {
      setState(() {
        order['type'] = 'rejected';
        order['status'] = 'Ditolak';
        order['reason'] = reason;
      });

      _showMessage('Pengajuan ditolak (simulasi).');
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              _detailRow('Kode Pesanan', '#${order['id']}'),
              _detailRow('Penyewa', order['customer']),
              _detailRow('Mobil', order['car']),
              _detailRow('Layanan', order['service']),
              if (order['price'] != '')
                _detailRow('Pembayaran', order['price']),
              if (order['reason'] != null)
                _detailRow('Alasan Ditolak', order['reason']),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: muted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOV RENT',
              style: TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'ADMIN HUB • PESANAN',
              style: TextStyle(
                color: dark,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showMessage('Belum ada notifikasi baru.'),
            icon: const Icon(
              Icons.notifications_none,
              color: dark,
              size: 25,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 17),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE3E9F5),
              child: Icon(Icons.person, color: primary),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // HEADER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pesanan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: dark,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '4 reservasi\nbutuh konfirmasi',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: primary,
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _formatDate(selectedDate),
                              style: const TextStyle(
                                fontSize: 11,
                                color: dark,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 17,
                              color: muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // TAB FILTER
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _tabButton('Perlu Konfirmasi', 0, '4'),
                      const SizedBox(width: 8),
                      _tabButton('Berjalan', 1, '15'),
                      const SizedBox(width: 8),
                      _tabButton('Selesai', 2, '142'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DAFTAR PESANAN
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 55,
                    color: Color(0xFFB9BECD),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada pesanan',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];

                return _orderCard(order);
              },
            ),
          ),
        ],
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.grid_view_rounded, 'Dashboard', 0),
                _navItem(Icons.directions_car_outlined, 'Armada', 1),
                _navItem(Icons.assignment_outlined, 'Pesanan', 2),
                _navItem(Icons.verified_user_outlined, 'Verifikasi', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index, String count) {
    final selected = selectedTab == index;

    return InkWell(
      onTap: () => setState(() => selectedTab = index),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? primary : const Color(0xFFF0F2FB),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : dark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFFE1E5F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: selected ? Colors.white : muted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final type = order['type'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KODE DAN STATUS
          Row(
            children: [
              Text(
                '#${order['id']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: dark,
                ),
              ),
              const SizedBox(width: 7),
              const Icon(Icons.circle, size: 4, color: muted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  order['time'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
              ),
              _statusBadge(order),
            ],
          ),

          const SizedBox(height: 16),

          // INFORMASI MOBIL
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 83,
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDF5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.directions_car,
                  size: 38,
                  color: Color(0xFF8995A8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['car'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: dark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order['service']} • ${order['duration']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['date'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          const Divider(height: 1, color: Color(0xFFEDEFF5)),

          const SizedBox(height: 11),

          // INFORMASI PENYEWA
          if (type == 'pending') ...[
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE2EAFF),
                  child: Text(
                    'BS',
                    style: TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              order['customer'],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (order['verified'] == true) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 12,
                              color: Colors.green,
                            ),
                            const Text(
                              'Terverifikasi',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        order['location'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  order['price'],
                  style: const TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 43,
              child: ElevatedButton(
                onPressed: () => _verifyOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Lakukan Verifikasi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 7),

            Center(
              child: TextButton(
                onPressed: () => _rejectOrder(order),
                child: const Text(
                  'Tolak Pengajuan',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],

          if (type == 'active') ...[
            Row(
              children: [
                const Icon(
                  Icons.navigation_outlined,
                  color: primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['customer'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dark,
                    ),
                  ),
                ),
                Text(
                  order['location'],
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallButton(
                    Icons.phone_outlined,
                    'Hubungi',
                        () => _showMessage('Fitur hubungi akan dihubungkan nanti.'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallButton(
                    Icons.visibility_outlined,
                    'Detail',
                        () => _showOrderDetail(order),
                  ),
                ),
              ],
            ),
          ],

          if (type == 'return') ...[
            Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: dark,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  order['location'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              height: 43,
              child: ElevatedButton.icon(
                onPressed: () => _showMessage(
                  'Fitur pemeriksaan fisik akan dibuat selanjutnya.',
                ),
                icon: const Icon(Icons.assignment_turned_in_outlined, size: 17),
                label: const Text(
                  'Mulai Cek Fisik',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(Map<String, dynamic> order) {
    final type = order['type'];

    Color color;
    Color bg;

    if (type == 'pending') {
      color = Colors.red;
      bg = const Color(0xFFFFEEEE);
    } else if (type == 'active') {
      color = primary;
      bg = const Color(0xFFE7EEFF);
    } else {
      color = const Color(0xFFD28A00);
      bg = const Color(0xFFFFF3D0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            order['status'],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallButton(
      IconData icon,
      String label,
      VoidCallback onTap,
      ) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F3FF),
          foregroundColor: primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = selectedNav == index;

    return InkWell(
      onTap: () {
        setState(() => selectedNav = index);

        if (index != 2) {
          _showMessage('Navigasi $label akan dihubungkan ke halaman admin.');
        }
      },
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected ? primary : const Color(0xFF555B6D),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? primary : const Color(0xFF555B6D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
