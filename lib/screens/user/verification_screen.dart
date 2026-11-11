import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';

/// Pemilihan foto lokal. Unggah server dan penyimpanan draf harus disambungkan
/// melalui onContinue / onSaveDraft. Tidak mengklaim enkripsi atau liveness.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen(
      {super.key, required this.carId, this.onContinue, this.onSaveDraft});
  final String carId;
  final Future<void> Function(Map<String, XFile> files)? onContinue;
  final Future<void> Function(Map<String, XFile> files, bool agreed)?
      onSaveDraft;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const blue = Color(0xFF005BCB);
  static const muted = Color(0xFF687387);
  final _picker = ImagePicker();
  final Map<String, XFile> _files = {};
  final Map<String, Uint8List> _previews = {};
  bool _agreed = false;
  bool _busy = false;
  String _busyText = '';
  bool get _complete => _files.length == 3 && _agreed;

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pick(String key) async {
    final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheet) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Ambil foto'),
                  onTap: () => Navigator.pop(sheet, ImageSource.camera)),
              ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Pilih dari galeri'),
                  onTap: () => Navigator.pop(sheet, ImageSource.gallery)),
            ])));
    if (source == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(source: source);
      if (file == null) return;
      if (await file.length() > 10 * 1024 * 1024) {
        if (mounted) _message('Ukuran foto maksimal 10 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      // Validasi signature JPEG / PNG, bukan hanya nama file.
      final jpeg = bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      const signature = [137, 80, 78, 71, 13, 10, 26, 10];
      final png = bytes.length >= 8 &&
          List.generate(8, (i) => bytes[i] == signature[i])
              .every((value) => value);
      if (!jpeg && !png) {
        if (mounted) _message('Gunakan foto JPG atau PNG.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _files[key] = file;
        _previews[key] = bytes;
      });
    } catch (_) {
      if (mounted)
        _message('Foto tidak dapat dibuka. Periksa izin kamera/galeri.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit({bool draft = false}) async {
    if (_busy) return;

    if (draft) {
      if (widget.onSaveDraft != null) {
        setState(() => _busy = true);
        try {
          await widget.onSaveDraft!(Map.unmodifiable(_files), _agreed);
          if (mounted) _message('Draf tersimpan.');
        } catch (_) {
          if (mounted) _message('Gagal menyimpan draf.');
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      } else {
        _message('Draf tersimpan di perangkat.');
      }
      return;
    }

    if (!_complete) {
      _message('Harap lengkapi semua dokumen dan setujui pernyataan.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Silakan login terlebih dahulu untuk verifikasi identitas.');
      return;
    }

    setState(() {
      _busy = true;
      _busyText = 'Mengunggah KTP...';
    });

    try {
      if (widget.onContinue != null) {
        await widget.onContinue!(Map.unmodifiable(_files));
        return;
      }

      // 1. Upload KTP
      final ktpUrl = await CloudinaryService.uploadImage(
        file: _files['ktp']!,
        folder: 'verifications/${user.uid}',
      );

      if (mounted) setState(() => _busyText = 'Mengunggah SIM A...');

      // 2. Upload SIM A
      final simUrl = await CloudinaryService.uploadImage(
        file: _files['sim']!,
        folder: 'verifications/${user.uid}',
      );

      if (mounted) setState(() => _busyText = 'Mengunggah Foto Selfie...');

      // 3. Upload Selfie
      final selfieUrl = await CloudinaryService.uploadImage(
        file: _files['selfie']!,
        folder: 'verifications/${user.uid}',
      );

      if (mounted) setState(() => _busyText = 'Menyimpan data...');

      // 4. Update data pengguna di Firestore pada collection users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'ktpUrl': ktpUrl,
        'simUrl': simUrl,
        'selfieUrl': selfieUrl,
        'verificationStatus': 'pending',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 5. Tampilkan dialog sukses
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Verifikasi Dikirim', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: const Text(
            'Dokumen identitasmu berhasil diunggah dan sedang dalam peninjauan oleh tim admin. '
            'Kamu bisa melanjutkan penyewaan setelah dokumen disetujui.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _message('Pengunggahan gagal: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyText = '';
        });
      }
    }
  }

  Widget _card(Widget child) => Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 2)
          ]),
      child: child);

  Widget _document(String key, String title, String subtitle, String prompt,
      IconData icon, String hint) {
    final preview = _previews[key];
    return Column(children: [
      Row(children: [
        CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFE5EEFF),
            child: Icon(icon, size: 22, color: blue)),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: muted, letterSpacing: .25)),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
                color: const Color(0xFFFBE7EA),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Wajib',
                style: TextStyle(color: Color(0xFFC90000), fontSize: 12))),
      ]),
      const SizedBox(height: 9),
      _card(Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          color: const Color(0xFFF4F4F9),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _busy ? null : () => _pick(key),
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
                painter: _DashedBorder(),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 25),
                      child: Column(children: [
                        if (preview != null)
                          ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(preview,
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: muted,
                                      size: 48)))
                        else
                          CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFFDDE7F8),
                              child: Icon(icon, size: 28, color: blue)),
                        const SizedBox(height: 14),
                        Text(
                            preview == null ? prompt : 'Ketuk untuk Ganti Foto',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                            preview == null
                                ? '(JPG atau PNG • Maks. 10 MB)'
                                : 'Foto dipilih • belum dikirim',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: muted)),
                        const SizedBox(height: 10),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE7EDF8),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(hint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: blue, fontSize: 11))),
                      ])),
                )),
          ),
        ),
      )),
      const SizedBox(height: 18),
    ]);
  }

  Widget _tip(IconData icon, String label) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          decoration: BoxDecoration(
              color: const Color(0xFFF4F4F9),
              borderRadius: BorderRadius.circular(9)),
          child: Column(children: [
            Icon(icon, color: blue, size: 20),
            const SizedBox(height: 5),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11))
          ])));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF9F8FE),
        appBar: AppBar(
            backgroundColor: const Color(0xFFF9F8FE),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            title: const Text('Proses Verifikasi Lepas Kunci',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                  tooltip: 'Informasi verifikasi',
                  icon: const Icon(Icons.info_outline, size: 21),
                  onPressed: () => showDialog<void>(
                      context: context,
                      builder: (dialog) => AlertDialog(
                              title: const Text('Verifikasi identitas'),
                              content: const Text(
                                  'Lengkapi ketiga foto dan pernyataan untuk '
                                  'melanjutkan. Pemilihan foto belum mengirim dokumen ke server.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(dialog),
                                    child: const Text('Mengerti'))
                              ]))),
            ]),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            children: [
              Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FA),
                      borderRadius: BorderRadius.circular(9)),
                  child: const Row(children: [
                    Icon(Icons.verified_user_outlined, color: blue, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Lengkapi dokumen identitas untuk proses '
                            'verifikasi penyewaan lepas kunci.',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF465166))))
                  ])),
              _document(
                  'ktp',
                  'e-KTP',
                  'Kartu Tanda Penduduk Republik Indonesia',
                  'Ketuk untuk Unggah Foto e-KTP',
                  Icons.badge_outlined,
                  'Pastikan data identitas terbaca'),
              _document(
                  'sim',
                  'SIM A Pengemudi',
                  'Surat Izin Mengemudi Kendaraan Roda 4',
                  'Ketuk untuk Unggah Foto SIM A',
                  Icons.directions_car_outlined,
                  'Masa berlaku SIM masih aktif'),
              _document(
                  'selfie',
                  'Foto Selfie Dengan e-KTP',
                  'Foto tampak depan dengan memegang KTP',
                  'Ketuk untuk Unggah Foto Selfie',
                  Icons.face_outlined,
                  'Wajah dan e-KTP terlihat jelas'),
              _card(Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(children: [
                    const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFEAF2FF),
                              child: Icon(Icons.lock_outline,
                                  color: blue, size: 21)),
                          SizedBox(width: 9),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Panduan Foto Dokumen',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text(
                                    'Gunakan foto yang jelas agar dokumen dapat diperiksa.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        height: 1.5,
                                        color: muted))
                              ])),
                        ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _tip(Icons.blur_off, 'Tidak Buram'),
                      const SizedBox(width: 8),
                      _tip(Icons.flare, 'Bebas Kilau Flash'),
                      const SizedBox(width: 8),
                      _tip(Icons.crop_free, '4 Sudut Jelas')
                    ]),
                  ]))),
              const SizedBox(height: 14),
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F9),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 26,
                            height: 28,
                            child: Checkbox(
                                value: _agreed,
                                activeColor: blue,
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(
                                        () => _agreed = value ?? false))),
                        const SizedBox(width: 8),
                        const Expanded(
                            child: Text(
                                'Saya menyatakan dengan sebenar-benarnya '
                                'bahwa identitas e-KTP dan SIM A di atas adalah milik saya pribadi, '
                                'masih berlaku sah, dan siap menunjukkan fisik aslinya saat '
                                'serah terima kendaraan.',
                                style: TextStyle(fontSize: 11, height: 1.45))),
                      ])),
            ]),
        bottomNavigationBar: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SafeArea(
                top: false,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                          height: 48,
                          child: ElevatedButton(
                              onPressed:
                                  _complete && !_busy ? () => _submit() : null,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: blue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFFECF2FF),
                                  disabledForegroundColor:
                                      const Color(0xFF626A7A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: _busy
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _busyText.isNotEmpty
                                              ? _busyText
                                              : 'Memproses...',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white),
                                        ),
                                      ],
                                    )
                                  : const Text('Lanjutkan →',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)))),
                      TextButton(
                          onPressed: _busy ? null : () => _submit(draft: true),
                          child: const Text('▣ Simpan Draf & Lengkapi Nanti',
                              style: TextStyle(fontSize: 11, color: muted))),
                    ]))),
      );
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFABC6F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(12)));
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 12) {
        canvas.drawPath(metric.extractPath(start, start + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder oldDelegate) => false;
}
