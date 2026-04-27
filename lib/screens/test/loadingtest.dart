// lib/utils/formatter.dart
// Reusable utility module for text & number formatting

/// Converts a string to title case.
///
/// [input] The string to format.
/// Returns a new string with the first letter of each word capitalized.
String toTitleCase(String input) {
  if (input.isEmpty) return input;
  
  return input.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

/// Formats a numeric value as currency.
///
/// [amount] The value to format.
/// [symbol] Currency symbol (defaults to '\$').
/// Returns a string with 2 decimal places and the specified symbol.
String formatCurrency(double amount, {String symbol = '\$'}) {
  return '$symbol${amount.toStringAsFixed(2)}';
}
