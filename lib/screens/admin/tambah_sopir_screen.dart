import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Tahap UI: data sopir dan foto hanya dikirim kembali ke Manajemen Sopir.
// Belum ada penyimpanan atau verifikasi berkas di Firestore.
class TambahSopirResult {
  final String name;
  final String phone;
  final String nik;
  final String gender;
  final String address;
  final String emergencyContact;
  final String emergencyPhone;
  final String carId;
  final String car;
  final String plate;
  final String? localPhotoPath;
  final List<String> skills;
  final String? localSimPhotoPath;

  const TambahSopirResult({
    required this.name,
    required this.phone,
    required this.nik,
    required this.gender,
    required this.address,
    required this.emergencyContact,
    required this.emergencyPhone,
    required this.carId,
    required this.car,
    required this.plate,
    required this.localPhotoPath,
    required this.skills,
    this.localSimPhotoPath,
  });
}

class TambahSopirScreen extends StatefulWidget {
  const TambahSopirScreen({super.key});

  @override
  State<TambahSopirScreen> createState() => _TambahSopirScreenState();
}

class _TambahSopirScreenState extends State<TambahSopirScreen> {
  static const blue = Color(0xFF2364EC);
  static const dark = Color(0xFF182238);
  static const muted = Color(0xFF727A90);
  static const pale = Color(0xFFF0F1FE);
  static const background = Color(0xFFF9F8FD);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();

  String? _gender;
  XFile? _photo;
  XFile? _simPhoto;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _address, _emergencyName, _emergencyPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> _selectImage({required bool sim}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Ambil dengan kamera'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(
        source: source, imageQuality: 80, maxWidth: 1200,
      );
      if (file == null || !mounted) return;
      final size = await File(file.path).length();
      if (!mounted) return;
      final extension = file.path.toLowerCase();
      if (!extension.endsWith('.jpg') &&
          !extension.endsWith('.jpeg') &&
          !extension.endsWith('.png')) {
        _message('Gunakan foto JPG atau PNG.');
        return;
      }
      if (size > 5 * 1024 * 1024) {
        _message('Ukuran foto maksimal 5 MB.');
        return;
      }
      setState(() {
        if (sim) {
          _simPhoto = file;
        } else {
          _photo = file;
        }
      });
    } catch (e) {
      if (mounted) _message('Foto belum bisa dipilih: $e');
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    for (final c in [
      _name, _phone, _address, _emergencyName, _emergencyPhone,
    ]) {
      c.clear();
    }
    setState(() {
      _gender = null;
      _photo = null;
      _simPhoto = null;
    });
  }

  void _submit() {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _message('Pilih jenis kelamin terlebih dahulu.');
      return;
    }
    setState(() => _saving = true);
    Navigator.pop(context, TambahSopirResult(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      nik: '', // NIK tidak dikumpulkan pada desain baru.
      gender: _gender!,
      address: _address.text.trim(),
      emergencyContact: _emergencyName.text.trim(),
      emergencyPhone: _emergencyPhone.text.trim(),
      carId: '',
      car: 'On-Call / Standby Pool',
      plate: '',
      localPhotoPath: _photo?.path,
      skills: const [],
      localSimPhotoPath: _simPhoto?.path,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      // Halaman dibuat di luar shell, jadi kembali lewat Navigator.pop.
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _pill('●  Pendaftaran Baru'),
              ),
              const SizedBox(height: 17),
              const Text('Tambah Driver Baru', style: TextStyle(
                color: dark, fontSize: 23, fontWeight: FontWeight.w800,
              )),
              const SizedBox(height: 5),
              const Text(
                'Registrasi pengemudi & verifikasi berkas legalitas mitra operasional',
                style: TextStyle(color: muted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 19),
              _card(Column(children: [
                Stack(children: [
                  CircleAvatar(
                    radius: 57,
                    backgroundColor: pale,
                    backgroundImage: _photo != null
                        ? FileImage(File(_photo!.path))
                        : null,
                    child: _photo == null
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.person_add_alt_1, size: 38, color: blue),
                      Text('Foto Profil', style: TextStyle(fontSize: 11, color: muted)),
                    ])
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      radius: 19, backgroundColor: blue,
                      child: IconButton(
                        onPressed: () => _selectImage(sim: false),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.camera_alt_outlined,
                            color: Colors.white, size: 19),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                const Text('Foto Identitas Pengemudi', style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: dark)),
                const SizedBox(height: 7),
                const Text(
                  'Format JPG/PNG maks. 5MB, wajah terlihat jelas mengenakan kemeja atau kaos berkerah rapi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 13),
                TextButton.icon(
                  onPressed: () => _selectImage(sim: false),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Pilih File / Ambil Kamera'),
                  style: TextButton.styleFrom(
                    backgroundColor: pale, foregroundColor: blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pale,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(children: [
                    Container(
                      width: 47,
                      height: 47,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _simPhoto == null
                          ? const Icon(Icons.badge_outlined, color: blue)
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_simPhoto!.path), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Foto Fisik SIM', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: dark,
                        )),
                        Text(
                          _simPhoto == null ? 'Belum diunggah' : 'Foto dipilih',
                          style: TextStyle(fontSize: 12,
                              color: _simPhoto == null ? Colors.red : Colors.green),
                        ),
                      ],
                    )),
                    TextButton.icon(
                      onPressed: () => _selectImage(sim: true),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 17),
                      label: const Text('Pilih File'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: blue,
                      ),
                    ),
                  ]),
                ),
              ])),
              const SizedBox(height: 19),
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(Icons.badge_outlined, 'Identitas & Kontak'),
                  _field('Nama Lengkap Sesuai KTP', _name,
                      hint: 'Cth. Bambang Trihatmojo', required: true),
                  _genderField(),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _idField()),
                    const SizedBox(width: 9),
                    Expanded(child: _field('WhatsApp / Telepon', _phone,
                        hint: '0812-xxxx-xxxx', digits: true, required: true)),
                  ]),
                  _field('Alamat Domisili Operasional', _address,
                      hint: 'Nama jalan, nomor rumah, RT/RW, kecamatan, kota',
                      required: true, lines: 2),
                  const Text('Kontak Darurat (Emergency Contact) *',
                      style: TextStyle(fontSize: 12, color: dark)),
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(child: _compactField(_emergencyName, 'Nama / hubungan')),
                    const SizedBox(width: 9),
                    Expanded(child: _compactField(_emergencyPhone, 'Nomor telepon', digits: true)),
                  ]),
                ],
              )),
              const SizedBox(height: 19),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: const Color(0xFFE9ECFF),
                    borderRadius: BorderRadius.circular(15)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, color: blue, size: 22),
                      SizedBox(width: 9),
                      Expanded(child: Text(
                        'Demo pendaftaran NOV Rent\nData sopir dan foto belum disimpan ke server. Verifikasi SIM dan penyimpanan aman memerlukan integrasi backend.',
                        style: TextStyle(color: dark, fontSize: 11, height: 1.35),
                      )),
                    ]),
              ),
              const SizedBox(height: 19),
              SizedBox(height: 51, child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Daftarkan & Simpan Sopir Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Reset Formulir'),
                  style: TextButton.styleFrom(foregroundColor: muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(19)),
    child: child,
  );

  Widget _pill(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFE0E6FF),
        borderRadius: BorderRadius.circular(22)),
    child: Text(value, style: const TextStyle(
        color: blue, fontWeight: FontWeight.bold, fontSize: 12)),
  );

  Widget _sectionTitle(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Row(children: [
      CircleAvatar(radius: 17, backgroundColor: const Color(0xFFDEE6FF),
          child: Icon(icon, color: blue, size: 19)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(
          color: dark, fontWeight: FontWeight.bold, fontSize: 18))),
    ]),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF959BB1)),
    filled: true, fillColor: pale,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    border: OutlineInputBorder(borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(13)),
    counterText: '',
  );

  Widget _field(String label, TextEditingController controller,
      {String hint = '', bool required = false,
        bool digits = false, int maxLength = 120, int lines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 15), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: dark)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          maxLines: lines,
          keyboardType: digits ? TextInputType.phone : TextInputType.text,
          decoration: _decoration(hint),
          style: const TextStyle(fontSize: 12),
          validator: (value) {
            final v = (value ?? '').trim();
            if (required && v.isEmpty) return '$label wajib diisi';
            return null;
          },
        ),
      ],
      ));

  Widget _genderField() => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Jenis Kelamin', style: TextStyle(fontSize: 12, color: dark)),
      const SizedBox(height: 7),
      DropdownButtonFormField<String>(
        initialValue: _gender,
        isExpanded: true,
        decoration: _decoration('Pilih jenis kelamin'),
        items: const ['Laki-Laki', 'Perempuan'].map((e) =>
            DropdownMenuItem(value: e, child: Text(e,
                style: TextStyle(fontSize: 12)))).toList(),
        onChanged: (value) => setState(() => _gender = value),
      ),
    ]),
  );

  Widget _idField() => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ID Mitra NOV', style: TextStyle(fontSize: 12, color: dark)),
      const SizedBox(height: 7),
      Container(height: 49, padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: pale,
              borderRadius: BorderRadius.circular(13)),
          child: const Text('#', style: TextStyle(fontSize: 19, color: muted))),
    ]),
  );

  Widget _compactField(TextEditingController controller,
      String hint, {bool digits = false}) => TextFormField(
    controller: controller,
    keyboardType: digits ? TextInputType.phone : TextInputType.text,
    decoration: _decoration(hint),
    style: const TextStyle(fontSize: 12),
    validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null,
  );

}
