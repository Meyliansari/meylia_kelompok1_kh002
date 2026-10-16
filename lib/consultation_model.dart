import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationModel {
  final String id;
  final String userId;
  final DateTime date;
  final String timeSlot;
  final String method; // Online / Offline
  final double landArea;
  final String budgetRange;
  final String houseStyle;
  final String notes;
  final double price;
  final String status; // Pending, Paid, Completed, Cancelled
  final DateTime paymentDeadline;
  final String? paymentProofUrl;
  final String? consultationResult;

  ConsultationModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.timeSlot,
    required this.method,
    required this.landArea,
    required this.budgetRange,
    required this.houseStyle,
    required this.notes,
    this.price = 150000.0,
    required this.status,
    required this.paymentDeadline,
    this.paymentProofUrl,
    this.consultationResult,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'method': method,
      'landArea': landArea,
      'budgetRange': budgetRange,
      'houseStyle': houseStyle,
      'notes': notes,
      'price': price,
      'status': status,
      'paymentDeadline': Timestamp.fromDate(paymentDeadline),
      'paymentProofUrl': paymentProofUrl,
      'consultationResult': consultationResult,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}