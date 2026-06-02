/// Emoji mapping utility for categories and transactions.
/// Centralized emoji definitions for consistent use across the app.
library;

/// Predefined emojis available for category selection (10-15 options)
const List<String> predefinedEmojis = [
  '🛍️', // Shopping
  '🍜', // Food/Restaurant
  '🚕', // Transportation
  '☕', // Cafe/Coffee
  '🏠', // Home
  '🎬', // Entertainment
  '💪', // Fitness
  '⚕️', // Medical
  '🎓', // Education
  '✈️', // Travel
  '⚡', // Utilities/Bills
  '🧾', // Bills/Documents
  '🔄', // Transfer
  '💰', // Money/Deposit
  '🎮', // Gaming
];

/// Get emoji for a category based on its name pattern.
/// Used for fallback when displaying transactions without a stored emoji.
String getEmojiForCategoryName(String categoryName) {
  final lower = categoryName.toLowerCase();

  // Special transaction types
  if (categoryName == 'deposit') return '💰';
  if (categoryName == 'internal_transfer') return '🔄';
  if (categoryName == 'transfer') return '💸';

  // Category name pattern matching
  if (lower.contains('food') ||
      lower.contains('ăn') ||
      lower.contains('restaurant')) {
    return '🍜';
  }
  if (lower.contains('shop') || lower.contains('mua')) {
    return '🛍️';
  }
  if (lower.contains('bill') || lower.contains('hóa đơn')) {
    return '🧾';
  }
  if (lower.contains('car') || lower.contains('xe')) {
    return '🚕';
  }
  if (lower.contains('cafe') || lower.contains('coffee')) {
    return '☕';
  }
  if (lower.contains('home') || lower.contains('nhà')) {
    return '🏠';
  }
  if (lower.contains('movie') ||
      lower.contains('cinema') ||
      lower.contains('phim')) {
    return '🎬';
  }
  if (lower.contains('fitness') || lower.contains('gym')) {
    return '💪';
  }
  if (lower.contains('medical') ||
      lower.contains('health') ||
      lower.contains('y tế')) {
    return '⚕️';
  }
  if (lower.contains('school') || lower.contains('education')) {
    return '🎓';
  }
  if (lower.contains('flight') ||
      lower.contains('travel') ||
      lower.contains('du lịch')) {
    return '✈️';
  }
  if (lower.contains('electric') ||
      lower.contains('utility') ||
      lower.contains('điện')) {
    return '⚡';
  }

  return '💳'; // Default generic payment emoji
}

/// Get emoji for transaction display based on flow direction.
/// Fallback when category emoji is not available.
String getDefaultTransactionEmoji(bool isIncrease) {
  return isIncrease ? '⬇️' : '⬆️';
}
