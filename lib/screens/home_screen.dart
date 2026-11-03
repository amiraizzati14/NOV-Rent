
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _blue = Color(0xFF005BCB);
  static const Color _background = Color(0xFFFAF9FD);
  static const Color _dark = Color(0xFF202124);

  bool _withDriver = false;

  String? _location;
  DateTime? _startDate;
  DateTime? _endDate;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final start = _startDate ?? today;

    final firstDate = isStart
        ? today
        : start.add(const Duration(days: 1));

    final initialDate = isStart
        ? (_startDate ?? today)
        : (_endDate ?? firstDate);

    final date = await showDatePicker(
      context: context,
      initialDate:
      initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || date == null) return;

    setState(() {
      if (isStart) {
        _startDate = date;

        if (_endDate != null && !_endDate!.isAfter(date)) {
          _endDate = null;
        }
      } else {
        _endDate = date;
      }
    });
  }

  Future<void> _selectLocation() async {
    const locations = [
      'Surabaya',
      'Jakarta',
      'Malang',
      'Yogyakarta',
      'Bandung',
      'Bali',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Pilih Lokasi Penjemputan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...locations.map(
                    (location) => ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: _blue,
                  ),
                  title: Text(location),
                  onTap: () {
                    Navigator.pop(context, location);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _location = selected;
    });
  }

  void _searchCars() {
    if (_location == null ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih lokasi dan tanggal sewa terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    if (!_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tanggal selesai harus setelah tanggal mulai.',
          ),
        ),
      );
      return;
    }

    context.push(
      '/cars',
      extra: {
        'location': _location,
        'startDate': _startDate,
        'endDate': _endDate,
        'withDriver': _withDriver,
      },
    );
  }

  Widget _dateBox({
    required String title,
    required String date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF626A65),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _blue : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : const Color(0xFF465047),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            context.push('/notifications');
                          },
                          icon: const Icon(
                            Icons.notifications_none,
                            size: 23,
                          ),
                        ),
                        Positioned(
                          right: 9,
                          top: 7,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Text(
                      'NOV RENT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    InkWell(
                      onTap: () => context.push('/profile'),
                      child: const CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFFE1E7F2),
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: _blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16, 10, 16, 20,
                ),
                children: [
                  const Text(
                    'Temukan mobil untuk\nperjalananmu.',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Bersih, terawat, dan siap mengantar petualangan Anda.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF707784),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Search card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE9E9EF),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Rental mode
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEEF1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _modeButton(
                                text: 'Lepas Kunci',
                                selected: !_withDriver,
                                onTap: () {
                                  setState(() {
                                    _withDriver = false;
                                  });
                                },
                              ),
                              _modeButton(
                                text: 'Dengan Sopir',
                                selected: _withDriver,
                                onTap: () {
                                  setState(() {
                                    _withDriver = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Location
                        InkWell(
                          onTap: _selectLocation,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F3F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Color(0xFF596273),
                                ),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    _location ??
                                        'Cari Lokasi Penjemputan',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                const Icon(
                                  Icons.unfold_more,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Rental dates
                        Row(
                          children: [
                            _dateBox(
                              title: 'Mulai Sewa',
                              date: _formatDate(_startDate),
                              onTap: () => _selectDate(true),
                            ),

                            const SizedBox(width: 8),

                            _dateBox(
                              title: 'Selesai Sewa',
                              date: _formatDate(_endDate),
                              onTap: () => _selectDate(false),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Search button
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: _searchCars,
                            icon: const Icon(
                              Icons.search,
                              size: 18,
                            ),
                            label: const Text(
                              'Cari Mobil Tersedia',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFFF2F3F7),
                              foregroundColor: _dark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Space before empty state
                  const SizedBox(height: 54),

                  // Empty state
                  Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCE5FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car_outlined,
                          color: _blue,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Cari mobil sesuai rencana perjalananmu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Pilih lokasi dan waktu sewa terlebih dahulu '
                            'untuk melihat mobil yang tersedia di sekitarmu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF626A7A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
