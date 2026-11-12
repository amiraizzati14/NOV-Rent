import 'package:flutter/material.dart';
import '../../services/car_service.dart';


// UI edit driver. Data disimpan sementara di layar Manajemen Sopir,
// BELUM mengubah Firebase / Cloud Firestore.
class EditSopirResult {
  final bool deleted;
  final String name, phone, status, car, plate, carId;
  const EditSopirResult({
    this.deleted = false,
    this.name = '',
    this.phone = '',
    this.status = 'Siap Jalan',
    this.car = '',
    this.plate = '',
    this.carId = '',
  });
}

class EditSopirScreen extends StatefulWidget {
  final String name, initials, car, plate;
  final String carId;
  final String phone;
  final bool busy;

  const EditSopirScreen({
    super.key,
    required this.name,
    required this.initials,
    required this.car,
    required this.plate,
    this.carId = '',
    required this.busy,
    this.phone = '0812-3456-7890',
  });

  @override
  State<EditSopirScreen> createState() => _EditSopirScreenState();
}


class _EditSopirScreenState extends State<EditSopirScreen> {
  static const blue = Color(0xFF0755C9);
  static const ink = Color(0xFF182238);
  static const muted = Color(0xFF697184);
  static const background = Color(0xFFF9F8FE);
  static const pale = Color(0xFFF0F2FD);
  static const green = Color(0xFF009575);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _car;
  late final TextEditingController _plate;
  late final TextEditingController _nik;
  late final TextEditingController _driverId;
  late final TextEditingController _address;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyPhone;
  String _selectedCarId = '';
  String _selectedCarImage = '';
  String _status = 'Siap Jalan';
  String _gender = 'Laki-Laki';
  bool _automatic = true;
  bool _manual = true;
  bool _english = false;
  bool _vip = false;

  @override
  void initState() {
    super.initState();
    _selectedCarId = widget.carId;
    _status = widget.busy ? 'Bertugas' : 'Siap Jalan';
    _name = TextEditingController(text: widget.name);
    _phone = TextEditingController(text: widget.phone);
    _car = TextEditingController(text: widget.car);
    _plate = TextEditingController(text: widget.plate);
    _nik = TextEditingController();
    _driverId = TextEditingController(text: 'DRV-NOV-082'); // ID contoh
    _address = TextEditingController();
    _emergencyName = TextEditingController();
    _emergencyPhone = TextEditingController();
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _phone, _car, _plate, _nik, _driverId,
      _address, _emergencyName, _emergencyPhone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _info(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(EditSopirResult(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      status: _status,
      car: _car.text.trim(),
      plate: _plate.text.trim(),
      carId: _selectedCarId,
    ));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Mitra Sopir?'),
        content: Text(
          'Hapus ${_name.text} dari daftar sopir contoh?\n\n'
              'Tindakan ini hanya mengubah data sementara, bukan Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Hapus',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, const EditSopirResult(deleted: true));
    }
  }

  // Mengambil armada yang SAMA dengan halaman Armada Admin dari Firestore.
  // Pemilihan ini hanya mengubah form sementara, belum data driver di database.
  Future<void> _changeCar() async {
    final selected = await showModalBottomSheet<Map<String, String>>(
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
    if (!mounted || selected == null) return;
    setState(() {
      _selectedCarId = selected['id'] ?? '';
      _car.text = selected['name'] ?? '';
      _plate.text = selected['plate'] ?? '';
      _selectedCarImage = selected['imageUrl'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Data Driver',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            )),
                        Text(
                          'ID: ${_driverId.text} • Edit Profil',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _tag('● Draft Aktif', blue, const Color(0xFFE0E8FF)),
                ],
              ),
              const SizedBox(height: 17),

              // FOTO, NAMA DAN STATUS
              _card(Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 57,
                        backgroundColor: const Color(0xFFE5EBFA),
                        child: Text(widget.initials,
                            style: const TextStyle(
                              color: blue,
                              fontSize: 29,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: InkWell(
                          onTap: () => _info(
                              'Ganti foto akan tersedia setelah integrasi penyimpanan.'),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: blue,
                            child: Icon(Icons.camera_alt_outlined,
                                color: Colors.white, size: 19),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_name.text.isEmpty ? widget.name : _name.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      )),
                  const SizedBox(height: 35),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('STATUS PENUGASAN REAL-TIME',
                        style: TextStyle(
                          fontSize: 12,
                          color: muted,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  const SizedBox(height: 9),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 3.2,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _statusChoice('Siap Jalan', green),
                      _statusChoice('Bertugas', blue),
                      _statusChoice('Cuti / Istirahat', Colors.orange),
                      _statusChoice('Nonaktif', Colors.grey),
                    ],
                  ),
                ],
              )),
              const SizedBox(height: 17),

              // IDENTITAS & KONTAK
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading(Icons.badge_outlined, 'Identitas & Kontak'),
                  _field('Nama Lengkap Sesuai KTP', _name, required: true),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field('NIK KTP', _nik, digits: true),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jenis Kelamin',
                              style: TextStyle(
                                color: ink,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 7),
                            DropdownButtonFormField<String>(
                              initialValue: _gender,
                              isExpanded: true,
                              decoration: _inputDecoration().copyWith(
                                constraints: const BoxConstraints(
                                  minHeight: 50,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 15,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Laki-Laki',
                                  child: Text(
                                    'Laki-Laki',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Perempuan',
                                  child: Text(
                                    'Perempuan',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _gender = value ?? _gender;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field('ID Mitra NOV', _driverId, enabled: false),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field('WhatsApp / Telepon', _phone,
                            digits: true, required: true),
                      ),
                    ],
                  ),
                  _field('Alamat Domisili Operasional', _address),
                  const Text('Kontak Darurat (Emergency Contact) *',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(child: _compactField(_emergencyName, 'Nama kontak')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _compactField(_emergencyPhone, 'Nomor telepon')),
                    ],
                  ),
                ],
              )),
              const SizedBox(height: 17),

              // UNIT ARMADA & KUALIFIKASI
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading(Icons.directions_car_outlined, 'Unit Armada & Wilayah'),
                  const Text('Armada Default / Sedang Dibawa',
                      style: TextStyle(fontSize: 12, color: ink)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: _selectedCarImage.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.network(_selectedCarImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.directions_car,
                                    color: muted, size: 29)),
                          )
                              : const Icon(Icons.directions_car,
                              color: muted, size: 29),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _car.text.isEmpty ? 'Belum ada mobil' : _car.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 5),
                              Text(_plate.text,
                                  style: const TextStyle(
                                      fontSize: 11, color: muted)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _changeCar,
                          child: const Text('Ubah ›'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  const Text(
                    'Spesialisasi & Kualifikasi Kemudi',
                    style: TextStyle(fontSize: 12, color: ink),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _skillChip('Transmisi Matic', _automatic,
                              (value) => setState(() => _automatic = value)),
                      _skillChip('Transmisi Manual', _manual,
                              (value) => setState(() => _manual = value)),
                      _skillChip('English Speaking (Tamu VIP)', _english,
                              (value) => setState(() => _english = value)),
                      _skillChip('Penjemputan VIP Bandara', _vip,
                              (value) => setState(() => _vip = value)),
                    ],
                  ),
                ],
              )),
              const SizedBox(height: 26),

              // TOMBOL AKSI
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Perubahan Data Sopir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hapus Mitra'),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDEDE),
                          foregroundColor: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
    ),
    child: child,
  );

  Widget _heading(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(children: [
      CircleAvatar(
        radius: 17,
        backgroundColor: const Color(0xFFE4EAFE),
        child: Icon(icon, color: blue, size: 19),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(label,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: ink)),
      ),
    ]),
  );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    filled: true,
    fillColor: pale,
    hintText: hint,
    hintStyle: const TextStyle(color: muted, fontSize: 12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _field(String label, TextEditingController controller,
      {bool required = false,
        bool digits = false,
        bool enabled = true,
        int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: ink)),
            const SizedBox(height: 7),
            TextFormField(
              controller: controller,
              enabled: enabled,
              maxLines: lines,
              keyboardType: digits ? TextInputType.number : TextInputType.text,
              style: const TextStyle(fontSize: 12),
              decoration: _inputDecoration(),
              validator: required
                  ? (v) => v == null || v.trim().isEmpty
                  ? '$label wajib diisi'
                  : null
                  : null,
            ),
          ],
        ),
      );

  Widget _compactField(TextEditingController controller, String hint) =>
      TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: _inputDecoration(hint: hint),
      );

  Widget _statusChoice(String label, Color dot) {
    final active = _status == label;
    return InkWell(
      onTap: () => setState(() => _status = label),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDBE3FF) : pale,
          borderRadius: BorderRadius.circular(11),
          border: active
              ? Border.all(color: const Color(0xFFBFCFFF))
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 5, backgroundColor: dot),
            const SizedBox(width: 7),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: ink)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillChip(
      String label,
      bool selected,
      ValueChanged<bool> onChanged,
      ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      onSelected: onChanged,
      backgroundColor: const Color(0xFFE8ECFF),
      selectedColor: blue,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : const Color(0xFF414A5C),
      ),
      shape: const StadiumBorder(side: BorderSide.none),
      side: BorderSide.none,
    );
  }

  Widget _tag(String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold, color: fg),
    ),
  );
}
