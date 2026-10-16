/// Ubah angka jadi format rupiah: 150000 → "Rp150.000"
String formatRupiah(int angka) {
  final s = angka.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return '${angka < 0 ? '-' : ''}Rp$buffer';
}