import 'package:flutter/material.dart';

class VerifikasiDokumenScreen extends StatefulWidget {
  const VerifikasiDokumenScreen({super.key});

  @override
  State<VerifikasiDokumenScreen> createState() => _VerifikasiDokumenScreenState();
}

class _VerifikasiDokumenScreenState extends State<VerifikasiDokumenScreen> {
  // State untuk checklist verifikasi petugas
  bool _nikMatch = true;
  bool _simActive = true;
  bool _biometricOk = true;
  bool _depositOk = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOV RENT - ADMIN',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=Admin&background=random'), // Placeholder avatar admin
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verifikasi Dokumen',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pemeriksaan identitas & uji liveness lepas kunci',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Card Info Pelanggan
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                      'https://ui-avatars.com/api/?name=Aisyah+Widia'), // Placeholder
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aisyah Widia Nugroho',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'NIK: 357821********0002',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '96% Cocok',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Card Info Kendaraan & Booking
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_outlined, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toyota Avanza 1.3 G',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Lepas Kunci • Booking #NR-9044 • 15-17 Mar (2 Hari)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Dokumen Terunggah
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dokumen Digital Terunggah',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '3 dari 3 Lengkap',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDocumentThumbnail('e-KTP Asli', 'Valid Dukcapil', true),
                _buildDocumentThumbnail('SIM A Mobil', 's.d 2028', true),
                _buildDocumentThumbnail('Selfie Wajah', 'Liveness OK', true),
              ],
            ),
            const SizedBox(height: 32),

            // Checklist Verifikasi Petugas
            const Text(
              'Checklist Verifikasi Petugas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildChecklistItem('Kesesuaian NIK Dukcapil', _nikMatch, (val) {
              setState(() => _nikMatch = val!);
            }),
            _buildChecklistItem('Masa Berlaku SIM A Aktif', _simActive, (val) {
              setState(() => _simActive = val!);
            }),
            _buildChecklistItem('Biometrik & Uji Liveness', _biometricOk, (val) {
              setState(() => _biometricOk = val!);
            }),
            _buildChecklistItem('Deposit & Kontak Darurat', _depositOk, (val) {
              setState(() => _depositOk = val!);
            }),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Logika tolak
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Tolak', style: TextStyle(color: Colors.blue)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Logika setujui
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Setujui', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget untuk kotak thumbnail dokumen
  Widget _buildDocumentThumbnail(String title, String subtitle, bool isValid) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  // Gunakan image placeholder atau NetworkImage dari Firebase nanti
                  image: NetworkImage('https://via.placeholder.com/100x70'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (isValid)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                ),
              )
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // Widget untuk baris checklist
  Widget _buildChecklistItem(String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
    );
  }
}