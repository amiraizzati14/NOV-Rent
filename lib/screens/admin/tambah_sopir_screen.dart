import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/car_service.dart';

// Tahap UI: daftar mobil dibaca dari Firestore, tetapi sopir baru hanya
// dikirim kembali ke Manajemen Sopir dan BELUM disimpan ke Firestore.
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
  final _nik = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();

  String? _gender;
  String _carId = '';
  String _carName = '';
  String _plate = '';
  String _carImageUrl = '';
  XFile? _photo;
  bool _saving = false;
  final Set<String> _skills = {'Transmisi Matic', 'Transmisi Manual'};

  @override
  void dispose() {
    for (final c in [
      _name, _nik, _phone, _address, _emergencyName, _emergencyPhone,
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

  Future<void> _selectPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Ambil foto kamera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (file == null || !mounted) return;
      final fileSize = await File(file.path).length();
      if (!mounted) return;
      if (fileSize > 5 * 1024 * 1024) {
        _message('Ukuran foto maksimal 5 MB.');
        return;
      }
      setState(() => _photo = file);
    } catch (e) {
      if (mounted) _message('Foto belum bisa dipilih: $e');
    }
  }

  Future<void> _chooseCar() async {
    final selection = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .68,
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Pilih Armada NOV Rent',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.not_interested_outlined),
              title: const Text('Tanpa unit armada (On-Call / Standby Pool)'),
              onTap: () => Navigator.pop(sheetContext, <String, String>{
                'id': '', 'name': '', 'plate': '', 'imageUrl': '',
              }),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder(
                stream: CarService().watchCars(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Gagal memuat daftar mobil: ${snapshot.error}',
                          textAlign: TextAlign.center),
                    ));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cars = snapshot.data!.docs;
                  if (cars.isEmpty) {
                    return const Center(child: Text('Belum ada mobil di Armada.'));
                  }
                  return ListView.builder(
                    itemCount: cars.length,
                    itemBuilder: (context, index) {
                      final doc = cars[index];
                      final data = doc.data();
                      final name = (data['name'] ?? 'Mobil').toString();
                      // Model Vehicle asli memuat name/imageUrl, sedangkan
                      // plat bisa berbeda nama field antar dokumen lama.
                      final plate = (data['plateNumber'] ??
                          data['plate'] ?? data['licensePlate'] ?? '-')
                          .toString();
                      final image = data['imageUrl'] is String
                          ? data['imageUrl'] as String
                          : '';
                      return ListTile(
                        leading: image.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(image,
                              width: 46, height: 46, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.directions_car)),
                        )
                            : const Icon(Icons.directions_car_outlined),
                        title: Text(name),
                        subtitle: Text(plate),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(sheetContext, {
                          'id': doc.id,
                          'name': name,
                          'plate': plate,
                          'imageUrl': image,
                        }),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
    if (!mounted || selection == null) return;
    setState(() {
      _carId = selection['id'] ?? '';
      _carName = selection['name'] ?? '';
      _plate = selection['plate'] ?? '';
      _carImageUrl = selection['imageUrl'] ?? '';
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    for (final c in [
      _name, _nik, _phone, _address, _emergencyName, _emergencyPhone,
    ]) {
      c.clear();
    }
    setState(() {
      _gender = null;
      _photo = null;
      _carId = '';
      _carName = '';
      _plate = '';
      _carImageUrl = '';
      _skills..clear()..addAll(['Transmisi Matic', 'Transmisi Manual']);
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
      nik: _nik.text.trim(),
      gender: _gender!,
      address: _address.text.trim(),
      emergencyContact: _emergencyName.text.trim(),
      emergencyPhone: _emergencyPhone.text.trim(),
      carId: _carId,
      car: _carName,
      plate: _plate,
      localPhotoPath: _photo?.path,
      skills: _skills.toList(),
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
                        ? const Icon(Icons.person_add_alt_1, size: 43, color: blue)
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      radius: 19, backgroundColor: blue,
                      child: IconButton(
                        onPressed: _selectPhoto,
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
                  onPressed: _selectPhoto,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Pilih File / Ambil Kamera'),
                  style: TextButton.styleFrom(
                    backgroundColor: pale, foregroundColor: blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ])),
              const SizedBox(height: 19),
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(Icons.badge_outlined, 'Identitas & Kontak'),
                  _field('Nama Lengkap Sesuai KTP', _name,
                      hint: 'Cth. Bambang Trihatmojo', required: true),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _field('NIK KTP', _nik,
                        hint: '16 digit', digits: true, maxLength: 16)),
                    const SizedBox(width: 9),
                    Expanded(child: _genderField()),
                  ]),
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
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle(Icons.car_rental_outlined, 'Unit Armada & Wilayah'),
                const Text('Unit Armada Awal (Opsional)',
                    style: TextStyle(fontSize: 12, color: dark)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _chooseCar,
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: pale,
                        borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      if (_carImageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(_carImageUrl, width: 36, height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.directions_car)),
                        )
                      else
                        const Icon(Icons.directions_car_outlined, color: muted),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        _carName.isEmpty
                            ? 'Pilih mobil default atau kosongkan'
                            : '$_carName  ·  $_plate',
                        style: const TextStyle(color: dark, fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      )),
                      const Icon(Icons.chevron_right, color: blue, size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 7),
                const Text('Jika dikosongkan, sopir akan berstatus "On-Call / Standby Pool".',
                    style: TextStyle(fontSize: 11, color: muted, height: 1.4)),
                const SizedBox(height: 20),
                const Text('Spesialisasi & Kualifikasi Kemudi',
                    style: TextStyle(fontSize: 12, color: dark)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _skill('Transmisi Matic'),
                  _skill('Transmisi Manual'),
                  _skill('English Speaking (Tamu VIP)'),
                  _skill('Penjemputan VIP Bandara'),
                ]),
              ])),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: const Color(0xFFE9ECFF),
                    borderRadius: BorderRadius.circular(15)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, color: blue, size: 22),
                      SizedBox(width: 9),
                      Expanded(child: Text(
                        'Simulasi Pendaftaran NOV Rent\nData form belum disimpan ke server. Integrasi Firestore dan verifikasi berkas dilakukan pada tahap CRUD.',
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
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SizedBox(height: 47, child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(backgroundColor: pale,
                      foregroundColor: dark),
                  child: const Text('Batal'),
                ))),
                const SizedBox(width: 8),
                Expanded(child: SizedBox(height: 47, child: TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: const Text('Reset Formulir'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDAD7),
                    foregroundColor: const Color(0xFFAE1824),
                  ),
                ))),
              ]),
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
            if (label == 'NIK KTP' && v.isNotEmpty &&
                !RegExp(r'^\d{16}$').hasMatch(v)) {
              return 'Harus 16 digit';
            }
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
        value: _gender,
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
          child: const Text('Otomatis saat disimpan ke database',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: muted))),
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

  Widget _skill(String label) {
    final selected = _skills.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (on) => setState(() {
        if (on) {
          _skills.add(label);
        } else {
          _skills.remove(label);
        }
      }),
      showCheckmark: true,
      checkmarkColor: Colors.white,
      selectedColor: const Color(0xFF0755C9),
      backgroundColor: const Color(0xFFE8ECFF),
      labelStyle: TextStyle(color: selected ? Colors.white : dark,
          fontSize: 11, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );
  }
}
