import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/car_service.dart';

/// Data yang dikembalikan ke ArmadaScreen setelah tombol Simpan ditekan.
class ArmadaFormData {
  const ArmadaFormData({
    this.id,
    this.isAvailable,
    required this.name,
    required this.plate,
    required this.year,
    required this.transmission,
    required this.seats,
    required this.fuel,
    required this.dailyPrice,
    required this.odometer,
    required this.bbmCondition,
  });

  final String? id;
  final bool? isAvailable;
  final String name;
  final String plate;
  final int year;
  final String transmission;
  final int seats;
  final String fuel;
  final int dailyPrice;
  final int odometer;
  final String bbmCondition;
}

class TambahArmadaScreen extends StatefulWidget {
  const TambahArmadaScreen({super.key, this.initialData});

  final ArmadaFormData? initialData;

  @override
  State<TambahArmadaScreen> createState() => _TambahArmadaScreenState();
}

class _TambahArmadaScreenState extends State<TambahArmadaScreen> {
  static const _blue = Color(0xFF0752C9);
  static const _ink = Color(0xFF152238);
  static const _muted = Color(0xFF8490A4);
  static const _pale = Color(0xFFF0F3FF);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _plate = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();
  final _odometer = TextEditingController();
  String _transmission = 'Matic (A/T)';
  String _seats = '7 Kursi';
  String _fuel = 'Bensin';
  String _bbm = 'Full (8/8)';
  bool _saving = false;

  bool get _isEditing => widget.initialData?.id != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;
    _name.text = data.name;
    _plate.text = data.plate;
    _year.text = data.year.toString();
    _price.text = data.dailyPrice.toString();
    _odometer.text = data.odometer.toString();
    _transmission = data.transmission == 'Matic' ? 'Matic (A/T)' : 'Manual (M/T)';
    _seats = '${data.seats} Kursi';
    _fuel = data.fuel;
    _bbm = data.bbmCondition;
  }

  @override
  void dispose() {
    for (final controller in [_name, _plate, _year, _price, _odometer]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showPhotoMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pemilihan foto dapat dihubungkan ke image_picker.')),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = ArmadaFormData(
      id: widget.initialData?.id,
      name: _name.text.trim(),
      plate: _plate.text.trim().toUpperCase(),
      year: int.parse(_year.text.trim()),
      transmission: _transmission.startsWith('Matic') ? 'Matic' : 'Manual',
      seats: int.parse(_seats.split(' ').first),
      fuel: _fuel,
      dailyPrice: int.parse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')),
      odometer: int.parse(_odometer.text.replaceAll(RegExp(r'[^0-9]'), '')),
      bbmCondition: _bbm,
    );
    setState(() => _saving = true);
    try {
      final payload = {
        'name': data.name,
        'plateNumber': data.plate,
        'plate': data.plate,
        'year': data.year,
        'transmission': data.transmission,
        'capacity': data.seats,
        'seats': data.seats,
        'fuelType': data.fuel,
        'fuel': data.fuel,
        'pricePerDay': data.dailyPrice,
        'dailyPrice': data.dailyPrice,
        'odometer': data.odometer,
        'bbmCondition': data.bbmCondition,
        'isAvailable': data.isAvailable ?? true,
        'status': (data.isAvailable ?? true) ? 'available' : 'rented',
      };
      final service = CarService();
      if (data.id == null) {
        await service.createCar(payload);
      } else {
        await service.updateCar(data.id!, payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan armada: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        title: Text(_isEditing ? 'Edit Unit Armada' : 'Tambah Unit Armada',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 15, 14, 22),
              children: [
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Foto Galeri Unit', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
                            SizedBox(height: 3),
                            Text('Tampilkan sudut depan, samping, dan interior bersih',
                                style: TextStyle(color: _muted, fontSize: 10.5)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE4EBFF), borderRadius: BorderRadius.circular(24)),
                          child: const Text('0/5\nTerunggah', textAlign: TextAlign.center,
                              style: TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showPhotoMessage,
                        child: Container(
                          height: 183,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1E8F1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Stack(children: [
                            Positioned.fill(child: Image.asset('assets/images/avanza.png', fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.directions_car_rounded, color: Color(0xFF71839C), size: 86)))),
                            Positioned(top: 10, left: 10, child: _photoPill(Icons.star_rounded, 'Foto Utama (Tampak Luar)')),
                            Positioned(right: 10, bottom: 10, child: _photoPill(Icons.add_a_photo_outlined, 'Ganti Foto')),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 9),
                      SizedBox(height: 83, child: Row(children: [
                        for (int i = 0; i < 3; i++) ...[
                          Expanded(child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset('assets/images/avanza.png', fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE1E8F1), child: const Icon(Icons.directions_car_outlined, color: _muted))),
                          )),
                          const SizedBox(width: 7),
                        ],
                        Expanded(child: InkWell(
                          onTap: _showPhotoMessage,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(10)),
                            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_a_photo_outlined, color: _muted, size: 24),
                              SizedBox(height: 4),
                              Text('Tambah', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        )),
                      ])),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                _section(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionTitle(Icons.directions_car_filled_outlined, 'Spesifikasi Kendaraan'),
                  const SizedBox(height: 12),
                  _input('Merk & Tipe Mobil', _name, hint: 'Toyota Avanza 1.3 G'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _input('Plat Nomor (Nopol)', _plate, hint: 'L 1422 AB')),
                    const SizedBox(width: 10),
                    Expanded(child: _input('Tahun Produksi', _year, hint: '2023', numeric: true,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1900 || n > DateTime.now().year + 1) return 'Tahun tidak valid';
                        return null;
                      })),
                  ]),
                  const SizedBox(height: 10),
                  _label('Tipe Transmisi'),
                  const SizedBox(height: 5),
                  Row(children: [
                    Expanded(child: _choice('Manual (M/T)', Icons.settings_outlined, _transmission == 'Manual (M/T)', () => setState(() => _transmission = 'Manual (M/T)'))),
                    const SizedBox(width: 7),
                    Expanded(child: _choice('Matic (A/T)', Icons.settings_suggest_outlined, _transmission == 'Matic (A/T)', () => setState(() => _transmission = 'Matic (A/T)'))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _select('Kapasitas Penumpang', _seats,
                      ['2 Kursi', '4 Kursi', '5 Kursi', '7 Kursi', '8 Kursi'], (v) => setState(() => _seats = v))),
                    const SizedBox(width: 10),
                    Expanded(child: _select('Bahan Bakar', _fuel,
                      ['Bensin', 'Diesel', 'Hybrid', 'Listrik'], (v) => setState(() => _fuel = v))),
                  ]),
                ])),
                const SizedBox(height: 13),
                _section(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionTitle(Icons.payments_outlined, 'Tarif & Layanan Sewa'),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Expanded(child: Text('Tarif (Harian)', style: TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 12))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE3F8EE), borderRadius: BorderRadius.circular(7)),
                      child: const Text('Unit Utama', style: TextStyle(color: Color(0xFF169A64), fontSize: 10, fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 7),
                  _inputField(_price, '350000', prefix: 'Rp', suffix: '/ 24 Jam', numeric: true),
                ])),
                const SizedBox(height: 13),
                _section(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionTitle(Icons.location_on_outlined, 'Pool & Kondisi Odometer'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _input('Odometer Saat Ini', _odometer, hint: '24850', numeric: true, suffix: 'KM')),
                    const SizedBox(width: 10),
                    Expanded(child: _select('Kondisi BBM', _bbm,
                      ['Full (8/8)', '7/8', '6/8', '5/8', '4/8', '3/8', '2/8', '1/8', 'Kosong'], (v) => setState(() => _bbm = v))),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.verified_user_outlined, color: _blue, size: 22),
                      SizedBox(width: 10),
                      Expanded(child: Text('Data armada disinkronisasi langsung ke sistem dispatch pusat NOV RENT dan platform pemesanan instan.',
                          style: TextStyle(color: _muted, fontSize: 10.5, height: 1.4))),
                    ]),
                  ),
                ])),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(top: false, child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEDF0F7)))),
        child: SizedBox(height: 49, child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined, size: 20),
          label: Text(_saving ? 'Menyimpan...' : 'Simpan Data Unit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
        )),
      )),
    );
  }

  Widget _section({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFF0F2F7))),
    child: child,
  );

  Widget _sectionTitle(IconData icon, String title) => Row(children: [
    Icon(icon, color: _blue, size: 18),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800)),
  ]);

  Widget _photoPill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(7)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _blue, size: 13),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: _ink, fontSize: 9.5, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _label(String value) => Text(value,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink));

  Widget _input(String label, TextEditingController controller, {
    required String hint, bool numeric = false, String? suffix,
    String? Function(String?)? validator,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label(label),
    const SizedBox(height: 5),
    _inputField(controller, hint, numeric: numeric, suffix: suffix, validator: validator),
  ]);

  Widget _inputField(TextEditingController controller, String hint, {
    bool numeric = false, String? prefix, String? suffix,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
    style: const TextStyle(fontSize: 12.5, color: _ink, fontWeight: FontWeight.w600),
    validator: validator ?? (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8891A7), fontSize: 12, fontWeight: FontWeight.w400),
      prefixText: prefix == null ? null : '$prefix ',
      suffixText: suffix,
      suffixStyle: const TextStyle(color: _muted, fontSize: 10),
      filled: true,
      fillColor: _pale,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
    ),
  );

  Widget _choice(String label, IconData icon, bool selected, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: selected ? _blue : _pale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: selected ? Colors.white : _muted),
        const SizedBox(width: 5),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _muted))),
      ]),
    ),
  );

  Widget _select(String label, String value, List<String> items, ValueChanged<String> onChange) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted, size: 16),
        style: const TextStyle(color: _ink, fontSize: 11.5, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          filled: true, fillColor: _pale, isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(10)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) { if (v != null) onChange(v); },
      ),
    ]);
}
