import 'package:flutter/material.dart';

// Halaman Edit Driver versi sederhana. Perubahan hanya disimpan sementara
// melalui EditSopirResult, belum disimpan ke Cloud Firestore.
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
  // Parameter dipertahankan agar cocok dengan Manajemen Sopir yang sudah ada.
  final String name, initials, car, plate;
  final String carId, phone;
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
  static const green = Color(0xFF09B98C);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _driverId;
  late final TextEditingController _address;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyPhone;

  String _status = 'Siap Jalan';
  String _gender = 'Laki-Laki';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _phone = TextEditingController(text: widget.phone);
    _driverId = TextEditingController(text: 'DRV-NOV-082'); // Contoh UI
    _address = TextEditingController();
    _emergencyName = TextEditingController();
    _emergencyPhone = TextEditingController();
    _status = widget.busy ? 'Bertugas' : 'Siap Jalan';
    _name.addListener(_refreshName);
  }

  void _refreshName() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.removeListener(_refreshName);
    for (final controller in [
      _name, _phone, _driverId, _address,
      _emergencyName, _emergencyPhone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // Mobil yang telah dipilih sebelumnya tetap dipertahankan.
    Navigator.of(context).pop(EditSopirResult(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      status: _status,
      car: widget.car,
      plate: widget.plate,
      carId: widget.carId,
    ));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Mitra Sopir?'),
        content: Text(
          'Hapus ${_name.text} dari daftar contoh?\n\n'
              'Ini belum menghapus data di Firestore.',
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
      Navigator.of(context).pop(const EditSopirResult(deleted: true));
    }
  }

  void _showSimInfo() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Pembaruan SIM A belum terhubung ke database.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
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
                        Text('ID: ${_driverId.text} • Edit Profil',
                            style: const TextStyle(fontSize: 12, color: muted)),
                      ],
                    ),
                  ),
                  _pill('● Draft Aktif', blue, const Color(0xFFE0E8FF)),
                ],
              ),
              const SizedBox(height: 18),

              // Profil + status + SIM A.
              _card(Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFE5EBFA),
                        child: Text(widget.initials,
                            style: const TextStyle(
                              color: blue,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: InkWell(
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Upload foto belum tersedia.'),
                          )),
                          child: const CircleAvatar(
                            backgroundColor: blue,
                            radius: 19,
                            child: Icon(Icons.camera_alt_outlined,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(_name.text.trim().isEmpty ? widget.name : _name.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      )),
                  const SizedBox(height: 45),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('STATUS PENUGASAN REAL-TIME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: muted,
                        )),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3.3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _statusChoice('Siap Jalan', green),
                      _statusChoice('Bertugas', blue),
                      _statusChoice('Cuti / Istirahat', Colors.orange),
                      _statusChoice('Nonaktif', Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2F8E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.badge_outlined,
                              color: Color(0xFF009A75)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('SIM A ', style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                                Icon(Icons.check_circle,
                                    color: Color(0xFF009A75), size: 17),
                              ]),
                              SizedBox(height: 3),
                              Text('Berlaku s/d 14 Okt 2028',
                                  style: TextStyle(fontSize: 12, color: muted)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showSimInfo,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: blue,
                          ),
                          child: const Text('Perbarui'),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 18),

              // Identitas & kontak. NIK dan bagian armada dihilangkan
              // sesuai mockup terbaru.
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading(Icons.badge_outlined, 'Identitas & Kontak'),
                  _field('Nama Lengkap Sesuai KTP', _name, required: true,
                      icon: Icons.badge_outlined),
                  const Text('Jenis Kelamin',
                      style: TextStyle(fontSize: 13, color: ink)),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: const [
                      DropdownMenuItem(
                          value: 'Laki-Laki', child: Text('Laki-Laki')),
                      DropdownMenuItem(
                          value: 'Perempuan', child: Text('Perempuan')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _gender = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _field('ID Mitra NOV', _driverId,
                          enabled: false)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('WhatsApp / Telepon', _phone,
                          digits: true, required: true)),
                    ],
                  ),
                  _field('Alamat Domisili Operasional', _address,
                      icon: Icons.location_on_outlined,
                      hint: 'Alamat domisili operasional'),
                  const Text('Kontak Darurat (Emergency Contact) *',
                      style: TextStyle(fontSize: 13, color: ink)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _compactField(_emergencyName, 'Nama / hubungan')),
                      const SizedBox(width: 9),
                      Expanded(child: _compactField(_emergencyPhone, 'Nomor kontak')),
                    ],
                  ),
                ],
              )),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2862EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Perubahan Data Sopir'),
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: ink,
                          backgroundColor: const Color(0xFFE8ECFF),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton.icon(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFA80000),
                          backgroundColor: const Color(0xFFFFDAD8),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hapus Mitra'),
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
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _heading(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(children: [
      CircleAvatar(
        radius: 19,
        backgroundColor: const Color(0xFFE0E6FF),
        child: Icon(icon, color: blue, size: 21),
      ),
      const SizedBox(width: 11),
      Expanded(child: Text(title, style: const TextStyle(
        fontSize: 19, fontWeight: FontWeight.w800, color: ink,
      ))),
    ]),
  );

  InputDecoration _inputDecoration({String? hint, IconData? icon}) =>
      InputDecoration(
        filled: true,
        fillColor: pale,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 20),
        hintStyle: const TextStyle(fontSize: 13, color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13, vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      );

  Widget _field(
      String label,
      TextEditingController controller, {
        bool required = false,
        bool digits = false,
        bool enabled = true,
        IconData? icon,
        String? hint,
      }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: ink)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: digits ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration(hint: hint, icon: icon),
          validator: required ? (value) =>
          (value == null || value.trim().isEmpty)
              ? '$label wajib diisi' : null : null,
        ),
      ],
    ),
  );

  Widget _compactField(TextEditingController controller, String hint) =>
      TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: _inputDecoration(hint: hint),
      );

  Widget _statusChoice(String label, Color dotColor) {
    final selected = _status == label;
    return InkWell(
      onTap: () => setState(() => _status = label),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDBE3FF) : pale,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          CircleAvatar(radius: 6, backgroundColor: dotColor),
          const SizedBox(width: 9),
          Flexible(child: Text(label, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: ink))),
        ]),
      ),
    );
  }

  Widget _pill(String label, Color foreground, Color fill) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(label, style: TextStyle(
      fontWeight: FontWeight.w700, fontSize: 12, color: foreground,
    )),
  );
}
