import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart'; // Import PaymentScreen agar bisa navigasi balik ke QRIS

class ConsultationHistoryScreen extends StatefulWidget {
  final String? userId;

  const ConsultationHistoryScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ConsultationHistoryScreen> createState() => _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  static const Color primaryDark = Color(0xFF2C3E35);
  late Future<List<QueryDocumentSnapshot>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    setState(() {
      _historyFuture = FirebaseFirestore.instance
          .collection('consultations')
          .get()
          .then((snapshot) => snapshot.docs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Riwayat Konsultasi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryDark),
            onPressed: _fetchHistory,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryDark),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Terjadi kesalahan: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada riwayat konsultasi.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchHistory,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryDark),
                    child: const Text('Coba Muat Ulang', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchHistory(),
            color: primaryDark,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                DateTime date = DateTime.now();
                if (data['date'] != null) {
                  date = (data['date'] as Timestamp).toDate();
                }

                final status = data['status'] ?? 'Pending';
                final timeSlot = data['timeSlot'] ?? '-';
                final method = data['method'] ?? 'Online';
                final style = data['houseStyle'] ?? '-';
                final landArea = data['landArea']?.toString() ?? '0';
                final price = (data['price'] ?? 150000).toDouble();
                final isPending = status == 'Pending';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMM yyyy').format(date),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'Paid' || status == 'Selesai'
                                    ? Colors.green.withOpacity(0.12)
                                    : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'Paid' || status == 'Selesai'
                                      ? Colors.green
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Waktu: $timeSlot ($method)', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Gaya: $style | Luas: $landArea m²',
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Jika status masih Pending, munculkan tombol Bayar Sekarang
                        if (isPending) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.qr_code_scanner, size: 18, color: Colors.white),
                              label: const Text(
                                'Bayar Sekarang / Lihat QRIS',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentScreen(
                                      consultationId: doc.id,
                                      amount: price,
                                    ),
                                  ),
                                );
                                // Refresh tampilan setelah kembali dari halaman pembayaran
                                _fetchHistory();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}