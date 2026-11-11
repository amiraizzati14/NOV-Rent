import 'package:flutter/material.dart';

/// Palet warna terpusat aplikasi NOV Rent
class AppColors {
  // Warna Utama (Branding NOV Rent)
  static const Color primary = Color(0xFF0057C2);
  static const Color primaryBlue = Color(0xFF005BCB);
  static const Color primaryLight = Color(0xFFEBF2FF);
  static const Color primarySoft = Color(0xFFF0F5FF);

  // Background & Surface
  static const Color background = Color(0xFFF7F8FA);
  static const Color backgroundLight = Color(0xFFFAF9FD);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE9ECF2);

  // Teks & Konten
  static const Color textDark = Color(0xFF1A1D26);
  static const Color textMuted = Color(0xFF757E8E);
  static const Color textSubtitle = Color(0xFF4A5568);

  // Status & Notifikasi
  static const Color success = Color(0xFF52C41A);
  static const Color successLight = Color(0xFFF6FFED);
  static const Color warning = Color(0xFFD46B08);
  static const Color warningLight = Color(0xFFFFF7E6);
  static const Color danger = Color(0xFFD92D20);
  static const Color dangerLight = Color(0xFFFDECEE);
}

/// Helper pemformatan terpusat (Harga, Tanggal, Jam, dan Inisial)
class AppFormatters {
  static const List<String> days = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu'
  ];

  static const List<String> monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  static const List<String> monthsLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  /// Format angka ke Rupiah: 350000 -> "Rp350.000"
  static String rupiah(dynamic value) {
    if (value == null) return 'Rp0';
    final intVal = value is num
        ? value.toInt()
        : int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 'Rp${intVal.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  /// Format tanggal singkat: "Kamis, 24 Okt"
  static String dateShort(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    final dayName = days[date.weekday % 7];
    final monthName = monthsShort[date.month - 1];
    return '$dayName, ${date.day} $monthName';
  }

  /// Format tanggal dengan tahun: "24 Okt 2024"
  static String dateWithYear(DateTime? date) {
    if (date == null) return '-';
    final monthName = monthsShort[date.month - 1];
    return '${date.day} $monthName ${date.year}';
  }

  /// Format tanggal lengkap: "Kamis, 24 Oktober 2024"
  static String dateFull(DateTime? date) {
    if (date == null) return '-';
    final dayName = days[date.weekday % 7];
    final monthName = monthsLong[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  /// Format jam: "09:00 WIB"
  static String timeWib(DateTime? date) {
    if (date == null) return '09:00 WIB';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  /// Format rentang tanggal: "18 Nov – 20 Nov 2024 (2 Hari)"
  static String dateRange(DateTime? start, DateTime? end, int daysCount) {
    if (start == null || end == null) return '-';
    return '${dateWithYear(start)} – ${dateWithYear(end)} ($daysCount Hari)';
  }

  /// Format inisial nama: "Dimas Suryaputra" -> "DS"
  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
