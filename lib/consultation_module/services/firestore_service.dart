import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsultationFirestoreService {
  ConsultationFirestoreService._();
  static final instance = ConsultationFirestoreService._();
  final db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> architects() =>
      db.collection('architects').orderBy('name').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> consultationsForAdmin() =>
      db.collection('consultations').orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> consultationsForArchitect() =>
      db.collection('consultations')
        .where('architectId', isEqualTo: uid)
        .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> slots() =>
      db.collection('consultation_slots').orderBy('startAt').snapshots();

  Future<void> saveArchitect({
    String? id, required String name, required String email,
    required String phone, required String specialty, required bool active,
  }) async {
    final ref = id == null ? db.collection('architects').doc() : db.collection('architects').doc(id);
    await ref.set({
      'name': name.trim(), 'email': email.trim(), 'phone': phone.trim(),
      'specialty': specialty.trim(), 'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setArchitectActive(String id, bool active) =>
      db.collection('architects').doc(id).update({
        'active': active, 'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> createWeeklySlots(DateTime weekStart, {int slotsPerDay = 4}) async {
    // Membuat slot 2 jam dari 09:00 sampai 17:00, Senin-Sabtu.
    final batch = db.batch();
    final monday = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final normalizedMonday = monday.subtract(Duration(days: monday.weekday - DateTime.monday));
    const starts = [9, 11, 13, 15];
    for (var day = 0; day < 6; day++) {
      for (var i = 0; i < slotsPerDay && i < starts.length; i++) {
        final start = DateTime(normalizedMonday.year, normalizedMonday.month, normalizedMonday.day + day, starts[i]);
        final end = start.add(const Duration(hours: 2));
        final id = '${start.year}${_two(start.month)}${_two(start.day)}_${_two(start.hour)}';
        final ref = db.collection('consultation_slots').doc(id);
        batch.set(ref, {
          'startAt': Timestamp.fromDate(start),
          'endAt': Timestamp.fromDate(end),
          'status': 'open', 'closedReason': null, 'consultationId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> closeSlot(String slotId, String reason) async {
    final ref = db.collection('consultation_slots').doc(slotId);
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Slot tidak ditemukan.');
      if (snap.data()?['status'] == 'booked') throw Exception('Slot sudah terisi konsultasi terkonfirmasi.');
      tx.update(ref, {'status': 'closed', 'closedReason': reason.trim(), 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> reopenSlot(String slotId) async {
    await db.collection('consultation_slots').doc(slotId).update({
      'status': 'open', 'closedReason': null, 'consultationId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> verifyConsultation({
    required String consultationId, required bool approve, String reason = '',
  }) async {
    final consultationRef = db.collection('consultations').doc(consultationId);
    await db.runTransaction((tx) async {
      final consultation = await tx.get(consultationRef);
      if (!consultation.exists) throw Exception('Data konsultasi tidak ditemukan.');
      final data = consultation.data()!;
      if (!['waiting_verification', 'Paid'].contains(data['status'])) {
        throw Exception('Konsultasi belum dibayar atau statusnya sudah berubah.');
      }
      final slotId = data['slotId'] as String?;
      final slotRef = slotId == null ? null : db.collection('consultation_slots').doc(slotId);
      if (approve) {
        tx.update(consultationRef, {
          'status': 'confirmed', 'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedBy': uid, 'rejectionReason': null,
        });
        if (slotRef != null) tx.update(slotRef, {
          'status': 'booked', 'consultationId': consultationId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _queueNotification(tx, data['userId'] as String?, 'Konsultasi dikonfirmasi',
          'Pembayaran konsultasi kamu sudah disetujui.', consultationId);
        _queueNotification(tx, data['architectId'] as String?, 'Jadwal konsultasi baru',
          'Ada konsultasi yang sudah dikonfirmasi. Periksa daftar tugas kamu.', consultationId);
      } else {
        if (reason.trim().isEmpty) throw Exception('Alasan penolakan wajib diisi.');
        tx.update(consultationRef, {
          'status': 'rejected', 'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedBy': uid, 'rejectionReason': reason.trim(),
        });
        if (slotRef != null) {
          tx.update(slotRef, {
            'status': 'open', 'consultationId': null, 'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (data['dateString'] != null && data['timeSlot'] != null) {
          final legacySlot = db.collection('booked_slots').doc('${data['dateString']}_${data['timeSlot']}');
          tx.delete(legacySlot);
        }
        _queueNotification(tx, data['userId'] as String?, 'Pembayaran ditolak',
          'Alasan: ${reason.trim()}', consultationId);
      }
    });
  }

  void _queueNotification(Transaction tx, String? recipientId, String title, String message, String consultationId) {
    if (recipientId == null || recipientId.isEmpty) return;
    final ref = db.collection('notifications').doc();
    tx.set(ref, {
      'recipientId': recipientId, 'title': title, 'message': message,
      'consultationId': consultationId, 'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> finishConsultation({
    required String consultationId, required String notes,
    required String recommendations, required String designFileUrl,
  }) async {
    final ref = db.collection('consultations').doc(consultationId);
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Konsultasi tidak ditemukan.');
      final data = snap.data()!;
      if (data['architectId'] != uid) throw Exception('Kamu bukan arsitek yang ditugaskan.');
      if (!['confirmed', 'in_progress'].contains(data['status'])) {
        throw Exception('Konsultasi belum dikonfirmasi atau sudah selesai.');
      }
      tx.update(ref, {
        'status': 'completed', 'resultNotes': notes.trim(),
        'recommendations': recommendations.trim(), 'designFileUrl': designFileUrl.trim(),
        'completedAt': FieldValue.serverTimestamp(),
      });
      _queueNotification(tx, data['userId'] as String?, 'Hasil konsultasi tersedia',
        'Arsitek sudah menyelesaikan konsultasi dan mengirimkan hasil.', consultationId);
    });
  }

  Future<void> startConsultation(String id, String meetingUrl) async {
    final ref = db.collection('consultations').doc(id);
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Konsultasi tidak ditemukan.');
      if (snap.data()?['architectId'] != uid) throw Exception('Tidak punya akses ke konsultasi ini.');
      if (snap.data()?['status'] != 'confirmed') throw Exception('Hanya konsultasi terkonfirmasi yang dapat dimulai.');
      tx.update(ref, {
        'status': 'in_progress', 'meetingUrl': meetingUrl.trim(),
        'startedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> createConsultation(Map<String, dynamic> data) async {
    // Dipakai oleh alur booking pengguna. Bukti pembayaran disimpan sebagai URL,
    // misalnya URL Firebase Storage; jangan simpan file gambar langsung di Firestore.
    final slotId = data['slotId'] as String;
    final slotRef = db.collection('consultation_slots').doc(slotId);
    final consultationRef = db.collection('consultations').doc();
    await db.runTransaction((tx) async {
      final slot = await tx.get(slotRef);
      if (!slot.exists || slot.data()?['status'] != 'open') {
        throw Exception('Slot sudah tidak tersedia.');
      }
      tx.set(consultationRef, {
        ...data, 'status': 'waiting_verification',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(slotRef, {
        'status': 'pending_verification', 'consultationId': consultationRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
