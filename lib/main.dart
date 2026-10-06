
import 'package:flutter/material.dart';
import 'profil.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Masukkan data praktikan
  final String nama = "Alvira Amelia Marasabessy";
  final String nim = "20240801280";
  final String hobi = "Sepeda";

  @override
  Widget build(BuildContext context) {
    // Mengambil digit terakhir NIM
    final int digitTerakhir =
    int.parse(nim[nim.length - 1]);

    // Menghitung skor aktivitas
    final int duaDigitTerakhir =
    int.parse(nim.substring(nim.length - 2));

    final int skorAktivitas =
        duaDigitTerakhir + 50;

    // Menentukan warna background
    final Color warnaBackground =
    digitTerakhir.isOdd
        ? Colors.tealAccent.shade100
        : Colors.amber.shade100;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tugas Layout Flutter',

      theme: ThemeData(
        scaffoldBackgroundColor: warnaBackground,
        useMaterial3: true,
      ),

      home: HomePage(
        nama: nama,
        nim: nim,
        hobi: hobi,
        skorAktivitas: skorAktivitas,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String nama;
  final String nim;
  final String hobi;
  final int skorAktivitas;

  const HomePage({
    super.key,
    required this.nama,
    required this.nim,
    required this.hobi,
    required this.skorAktivitas,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil Praktikan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: ProfileCard(
            nama: nama,
            nim: nim,
            hobi: hobi,
            skorAktivitas: skorAktivitas,
          ),
        ),
      ),
    );
  }
}