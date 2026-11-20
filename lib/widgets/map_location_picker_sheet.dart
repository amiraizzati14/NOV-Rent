import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';

/// Model hasil pemilihan lokasi pengantaran
class MapLocationResult {
  final String address;
  final String? notes;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const MapLocationResult({
    required this.address,
    this.notes,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  bool get isWithin5Km => distanceKm <= 5.0;
}

/// Sheet Pemilihan Titik Lokasi Peta bergaya Gojek/Grab
/// Dilengkapi kalkulasi radius 5 km real-time dari Pool NOV Rent
class MapLocationPickerSheet extends StatefulWidget {
  final double poolLat;
  final double poolLng;
  final String poolAddress;
  final double? initialLat;
  final double? initialLng;
  final String? initialNotes;
  final double maxDistanceKm;

  const MapLocationPickerSheet({
    super.key,
    required this.poolLat,
    required this.poolLng,
    this.poolAddress = 'Pool NOV Rent',
    this.initialLat,
    this.initialLng,
    this.initialNotes,
    this.maxDistanceKm = 5.0,
  });

  /// Static helper untuk membuka picker via BottomSheet atau Route
  static Future<MapLocationResult?> show(
    BuildContext context, {
    required double poolLat,
    required double poolLng,
    String poolAddress = 'Pool NOV Rent',
    double? initialLat,
    double? initialLng,
    String? initialNotes,
    double maxDistanceKm = 5.0,
  }) {
    return showModalBottomSheet<MapLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => MapLocationPickerSheet(
        poolLat: poolLat,
        poolLng: poolLng,
        poolAddress: poolAddress,
        initialLat: initialLat,
        initialLng: initialLng,
        initialNotes: initialNotes,
        maxDistanceKm: maxDistanceKm,
      ),
    );
  }

  @override
  State<MapLocationPickerSheet> createState() => _MapLocationPickerSheetState();
}

class _MapLocationPickerSheetState extends State<MapLocationPickerSheet>
    with SingleTickerProviderStateMixin {
  late double _centerLat;
  late double _centerLng;
  late int _zoom;
  late double _currentDistance;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _resolvedAddress = 'Mencari alamat lokasi...';
  bool _isGeocoding = false;
  Timer? _geocodeDebounce;

  // Pin animation
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.initialLat ?? widget.poolLat;
    _centerLng = widget.initialLng ?? widget.poolLng;
    _zoom = 15;
    _currentDistance = _calculateDistance(
      widget.poolLat,
      widget.poolLng,
      _centerLat,
      _centerLng,
    );
    if (widget.initialNotes != null) {
      _notesController.text = widget.initialNotes!;
    }
    _fetchAddress(_centerLat, _centerLng);
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Rumus Haversine untuk kalkulasi jarak GPS dalam kilometer
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(math.max(0.0, a)));
  }

  /// Reverse geocoding via OpenStreetMap Nominatim API
  Future<void> _fetchAddress(double lat, double lng) async {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _isGeocoding = true);

      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
        );
        final res = await http.get(url, headers: {
          'User-Agent': 'NOVRentApp-Flutter/1.0 (contact: info@novrent.com)',
          'Accept-Language': 'id,en',
        }).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final addr = data['address'] as Map<String, dynamic>?;

          String formatted = '';
          if (addr != null) {
            final road = addr['road'] ?? addr['pedestrian'] ?? addr['suburb'] ?? '';
            final neighbourhood = addr['neighbourhood'] ?? addr['village'] ?? '';
            final city = addr['city'] ?? addr['city_district'] ?? addr['county'] ?? '';
            final parts = [road, neighbourhood, city]
                .where((s) => s.toString().trim().isNotEmpty)
                .toList();

            if (parts.isNotEmpty) {
              formatted = parts.join(', ');
            }
          }

          if (formatted.isEmpty) {
            formatted = data['display_name']?.toString() ??
                'Titik Lokasi (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
          }

          if (mounted) {
            setState(() {
              _resolvedAddress = formatted;
              _isGeocoding = false;
            });
          }
          return;
        }
      } catch (_) {
        // Fallback gracefully jika offline / error
      }

      if (mounted) {
        setState(() {
          _resolvedAddress =
              'Koordinat: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
          _isGeocoding = false;
        });
      }
    });
  }

  /// Pindah posisi peta berdasarkan pergeseran delta pixel layar
  void _onPanUpdate(DragUpdateDetails details, Size mapSize) {
    setState(() {
      _isDragging = true;
      final worldSize = 256.0 * (1 << _zoom);

      // Konversi centerLat & centerLng ke pixel world
      final currentPxX = (_centerLng + 180.0) / 360.0 * worldSize;
      final sinLat =
          math.sin(_centerLat * math.pi / 180.0).clamp(-0.9999, 0.9999);
      final currentPxY =
          (0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi)) *
              worldSize;

      // Geser sesuai drag (geser jari ke kanan -> peta gerak kanan -> koordinat center mundur ke kiri)
      final newPxX = currentPxX - details.delta.dx;
      final newPxY = currentPxY - details.delta.dy;

      // Konversi balik ke Lat & Lng
      _centerLng = (newPxX / worldSize * 360.0 - 180.0).clamp(-180.0, 180.0);
      final n = math.pi - 2.0 * math.pi * newPxY / worldSize;
      _centerLat = (180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n))))
          .clamp(-85.0, 85.0);

      _currentDistance = _calculateDistance(
        widget.poolLat,
        widget.poolLng,
        _centerLat,
        _centerLng,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _fetchAddress(_centerLat, _centerLng);
  }

  void _zoomIn() {
    if (_zoom < 18) {
      setState(() => _zoom++);
      _fetchAddress(_centerLat, _centerLng);
    }
  }

  void _zoomOut() {
    if (_zoom > 11) {
      setState(() => _zoom--);
      _fetchAddress(_centerLat, _centerLng);
    }
  }

  void _resetToPool() {
    setState(() {
      _centerLat = widget.poolLat;
      _centerLng = widget.poolLng;
      _currentDistance = 0.0;
    });
    _fetchAddress(_centerLat, _centerLng);
  }

  void _selectPreset(String name, double lat, double lng) {
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _currentDistance = _calculateDistance(
        widget.poolLat,
        widget.poolLng,
        _centerLat,
        _centerLng,
      );
    });
    _fetchAddress(lat, lng);
  }

  void _confirmSelection() {
    if (_currentDistance > widget.maxDistanceKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lokasi di luar jangkauan (${_currentDistance.toStringAsFixed(1)} km). Maksimal ${widget.maxDistanceKm.toInt()} km dari pool!',
          ),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = MapLocationResult(
      address: _resolvedAddress,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      latitude: _centerLat,
      longitude: _centerLng,
      distanceKm: _currentDistance,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfRange = _currentDistance > widget.maxDistanceKm;
    final double sheetHeight = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            // ============================================
            // 1. TOP HEADER BAR
            // ============================================
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE9ECF2))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Titik Antar di Peta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Maksimal 5 km dari Pool NOV Rent',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Indikator status jarak di header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isOutOfRange
                          ? AppColors.dangerLight
                          : AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOutOfRange
                            ? AppColors.danger.withOpacity(0.3)
                            : AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOutOfRange ? Icons.warning_rounded : Icons.check_circle,
                          size: 13,
                          color: isOutOfRange
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentDistance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOutOfRange
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ============================================
            // 2. PRESET LOKASI CEPAT (CHIPS)
            // ============================================
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Rekomendasi: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    _presetChip('Pool NOV Rent (0 km)', widget.poolLat, widget.poolLng),
                    _presetChip('Cisalak (~0.8 km)', -6.3880, 106.8380),
                    _presetChip('Komp. Pelni (~1.5 km)', -6.3800, 106.8400),
                    _presetChip('Jl. Juanda (~2.4 km)', -6.3750, 106.8450),
                    _presetChip('Margonda Raya (~3.8 km)', -6.3700, 106.8320),
                    _presetChip('Univ. Indonesia (~4.6 km)', -6.3600, 106.8280),
                    _presetChip('Cibinong (9 km - Tes Di Luar)', -6.4780, 106.8520, isTestOut: true),
                  ],
                ),
              ),
            ),

            // ============================================
            // 3. MAP CANVAS INTERAKTIF (SLIPPY MAP + PIN)
            // ============================================
            Expanded(
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final size =
                          Size(constraints.maxWidth, constraints.maxHeight);

                      return GestureDetector(
                        onPanUpdate: (d) => _onPanUpdate(d, size),
                        onPanEnd: _onPanEnd,
                        onDoubleTap: _zoomIn,
                        child: Container(
                          color: const Color(0xFFE4E8EE),
                          child: Stack(
                            children: [
                              // Layer 1: Tile Peta OpenStreetMap
                              _SlippyMapTiles(
                                centerLat: _centerLat,
                                centerLng: _centerLng,
                                zoom: _zoom,
                                viewportSize: size,
                              ),

                              // Layer 2: Lingkaran Radius 5 KM & Pin Pool
                              CustomPaint(
                                size: size,
                                painter: _RadiusAndPoolPainter(
                                  centerLat: _centerLat,
                                  centerLng: _centerLng,
                                  zoom: _zoom,
                                  poolLat: widget.poolLat,
                                  poolLng: widget.poolLng,
                                  maxDistanceKm: widget.maxDistanceKm,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Center Pin Marker (Gojek / Grab Style)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 38),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tooltip di atas pin
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isOutOfRange
                                  ? AppColors.danger
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOutOfRange
                                      ? Icons.cancel_outlined
                                      : Icons.directions_car,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOutOfRange
                                      ? 'Di Luar 5 km'
                                      : 'Antar ke Sini',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Pin Icon
                          AnimatedScale(
                            scale: _isDragging ? 1.25 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              Icons.location_on,
                              size: 42,
                              color: isOutOfRange
                                  ? AppColors.danger
                                  : AppColors.primary,
                              shadows: const [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pin Shadow di bawah pin
                  Center(
                    child: Container(
                      width: 10,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Floating Controls (Zoom In, Zoom Out, Reset to Pool)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Column(
                      children: [
                        _mapControlBtn(
                          icon: Icons.my_location,
                          tooltip: 'Pusatkan ke Pool',
                          onTap: _resetToPool,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        _mapControlBtn(
                          icon: Icons.add,
                          tooltip: 'Perbesar',
                          onTap: _zoomIn,
                        ),
                        const SizedBox(height: 6),
                        _mapControlBtn(
                          icon: Icons.remove,
                          tooltip: 'Perkecil',
                          onTap: _zoomOut,
                        ),
                      ],
                    ),
                  ),

                  // Mini Petunjuk Drag di atas peta
                  Positioned(
                    top: 10,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_outlined,
                              size: 13, color: AppColors.textSubtitle),
                          SizedBox(width: 4),
                          Text(
                            'Geser peta untuk menentukan titik',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSubtitle,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ============================================
            // 4. BOTTOM SHEET DETAIL ALAMAT & KONFIRMASI
            // ============================================
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status radius & jarak badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOutOfRange
                                ? AppColors.dangerLight
                                : AppColors.successLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOutOfRange
                                    ? Icons.error_outline
                                    : Icons.verified_outlined,
                                size: 14,
                                color: isOutOfRange
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOutOfRange
                                    ? 'Di Luar Area Antar (Maks. 5 km)'
                                    : 'Dalam Jangkauan Pengantaran',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfRange
                                      ? AppColors.danger
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_currentDistance.toStringAsFixed(1)} km dari Pool',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Alamat hasil Geocoding
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isGeocoding) ...[
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Mendeteksi alamat titik...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  _resolvedAddress,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Input Catatan Patokan Driver
                    TextField(
                      controller: _notesController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText:
                            'Catatan / patokan (misal: Pagar hitam depan pos satpam)',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(Icons.edit_note,
                            size: 18, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                        fillColor: const Color(0xFFFAFAFC),
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Warning bila di luar jangkauan
                    if (isOutOfRange) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.danger.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jarak lokasi pengantaran melebihi batas 5 km (${_currentDistance.toStringAsFixed(1)} km). Silakan geser pin ke dalam lingkaran radius.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Tombol Konfirmasi Lokasi
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _confirmSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfRange
                              ? const Color(0xFFCBD5E1)
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isOutOfRange
                              ? 'Lokasi di Luar Jangkauan (Maks. 5 km)'
                              : 'Gunakan Titik Lokasi Ini',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, double lat, double lng,
      {bool isTestOut = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isTestOut ? AppColors.danger : AppColors.primary,
        ),
        backgroundColor:
            isTestOut ? AppColors.dangerLight : const Color(0xFFEBF2FF),
        side: BorderSide(
          color: isTestOut
              ? AppColors.danger.withOpacity(0.3)
              : const Color(0xFFD0E1FD),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: () => _selectPreset(label, lat, lng),
      ),
    );
  }

  Widget _mapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: color ?? AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

/// Renderer Tile Peta OpenStreetMap (Slippy Map)
class _SlippyMapTiles extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final int zoom;
  final Size viewportSize;

  const _SlippyMapTiles({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.viewportSize,
  });

  @override
  Widget build(BuildContext context) {
    final worldSize = 256.0 * (1 << zoom);

    // Pixel koordinat world untuk centerLat & centerLng
    final centerPxX = (centerLng + 180.0) / 360.0 * worldSize;
    final sinLat =
        math.sin(centerLat * math.pi / 180.0).clamp(-0.9999, 0.9999);
    final centerPxY =
        (0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi)) *
            worldSize;

    final halfW = viewportSize.width / 2.0;
    final halfH = viewportSize.height / 2.0;

    final minTileX = ((centerPxX - halfW) / 256.0).floor();
    final maxTileX = ((centerPxX + halfW) / 256.0).floor();
    final minTileY = ((centerPxY - halfH) / 256.0).floor();
    final maxTileY = ((centerPxY + halfH) / 256.0).floor();

    final maxTileCount = 1 << zoom;
    final tiles = <Widget>[];

    for (int tx = minTileX; tx <= maxTileX; tx++) {
      for (int ty = minTileY; ty <= maxTileY; ty++) {
        if (ty < 0 || ty >= maxTileCount) continue;
        final wrappedX = (tx % maxTileCount + maxTileCount) % maxTileCount;

        final tileLeft = tx * 256.0 - (centerPxX - halfW);
        final tileTop = ty * 256.0 - (centerPxY - halfH);

        tiles.add(
          Positioned(
            left: tileLeft,
            top: tileTop,
            width: 256,
            height: 256,
            child: Image.network(
              'https://tile.openstreetmap.org/$zoom/$wrappedX/$ty.png',
              headers: const {
                'User-Agent': 'NOVRentApp-Flutter/1.0 (contact: info@novrent.com)',
              },
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE2E8F0),
                child: const Center(
                  child: Icon(Icons.map_outlined, color: Colors.black26),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: tiles);
  }
}

/// Painter untuk menggambar radius 5 KM dan ikon Pool NOV Rent
class _RadiusAndPoolPainter extends CustomPainter {
  final double centerLat;
  final double centerLng;
  final int zoom;
  final double poolLat;
  final double poolLng;
  final double maxDistanceKm;

  _RadiusAndPoolPainter({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.poolLat,
    required this.poolLng,
    required this.maxDistanceKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final worldSize = 256.0 * (1 << zoom);

    // Hitung posisi pixel center saat ini di layar
    final centerPxX = (centerLng + 180.0) / 360.0 * worldSize;
    final sinCenter =
        math.sin(centerLat * math.pi / 180.0).clamp(-0.9999, 0.9999);
    final centerPxY =
        (0.5 - math.log((1.0 + sinCenter) / (1.0 - sinCenter)) / (4.0 * math.pi)) *
            worldSize;

    // Hitung posisi pixel Pool di layar
    final poolPxX = (poolLng + 180.0) / 360.0 * worldSize;
    final sinPool = math.sin(poolLat * math.pi / 180.0).clamp(-0.9999, 0.9999);
    final poolPxY =
        (0.5 - math.log((1.0 + sinPool) / (1.0 - sinPool)) / (4.0 * math.pi)) *
            worldSize;

    final poolScreenX = poolPxX - (centerPxX - size.width / 2.0);
    final poolScreenY = poolPxY - (centerPxY - size.height / 2.0);

    // Hitung radius 5 KM dalam pixel layar
    // Resolusi tanah (meter/pixel) di lintang pool:
    final metersPerPixel =
        156543.03392 * math.cos(poolLat * math.pi / 180.0) / (1 << zoom);
    final radiusPixels = (maxDistanceKm * 1000.0) / metersPerPixel;

    final poolCenter = Offset(poolScreenX, poolScreenY);

    // 1. Gambar Area Radius 5 KM (Fill Transparan)
    final fillPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(poolCenter, radiusPixels, fillPaint);

    // 2. Gambar Border Radius 5 KM (Garis Putus-Putus / Border)
    final borderPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(poolCenter, radiusPixels, borderPaint);

    // 3. Gambar Label Batas 5 KM di atas lingkaran
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Batas Pengantaran 5 KM',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(poolScreenX - textPainter.width / 2, poolScreenY - radiusPixels - 14),
    );

    // 4. Gambar Marker Pool NOV Rent
    // Titik pusat pool
    final poolPinBg = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(poolCenter, 14, poolPinBg);

    final poolPinInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(poolCenter, 6, poolPinInner);

    // Label Pool NOV Rent
    final poolLabelPainter = TextPainter(
      text: const TextSpan(
        text: ' Pool NOV Rent ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xFF1E293B),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    poolLabelPainter.paint(
      canvas,
      Offset(poolScreenX - poolLabelPainter.width / 2, poolScreenY + 16),
    );
  }

  @override
  bool shouldRepaint(covariant _RadiusAndPoolPainter oldDelegate) {
    return oldDelegate.centerLat != centerLat ||
        oldDelegate.centerLng != centerLng ||
        oldDelegate.zoom != zoom ||
        oldDelegate.poolLat != poolLat ||
        oldDelegate.poolLng != poolLng;
  }
}
