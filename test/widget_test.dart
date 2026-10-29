import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nov_rent/main.dart';

void main() {
  testWidgets('App loads successfully smoke test', (WidgetTester tester) async {
    // Jalankan aplikasi NOV Rent kita, bukan MyApp
    await tester.pumpWidget(const NovRentApp());

    // Tunggu proses routing go_router selesai
    await tester.pumpAndSettle();

    // Verifikasi sederhana bahwa MaterialApp berhasil dimuat ke layar
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}