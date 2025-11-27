/// Formatea un número con separador de miles (punto) y símbolo de pesos
/// Ejemplo: 80000 -> "\$80.000"
String formatCurrency(double amount) {
  final formatter = amount.toStringAsFixed(0);
  final reversed = formatter.split('').reversed.toList();
  final result = <String>[];
  for (int i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) result.add('.');
    result.add(reversed[i]);
  }
  return '\$${result.reversed.join()}';
}
