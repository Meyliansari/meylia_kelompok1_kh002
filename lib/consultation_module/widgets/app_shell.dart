import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF77786F))),
        ]),
      ),
      body: SafeArea(child: child),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF203D33)))),
    if (trailing != null) trailing!,
  ]);
}

String prettyDate(dynamic value) {
  DateTime? date;
  if (value is DateTime) date = value;
  if (value is dynamic && value != null && value.toDate is Function) {
    try { date = value.toDate(); } catch (_) {}
  }
  if (date == null) return '-';
  const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
