import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';

abstract class BudgetRemoteDataSource {
  Stream<List<CategoryModel>> watchBudgetCategories(
    String walletId, {
    int? month,
    int? year,
  });

  Future<void> upsertBudgetCategory(CategoryModel category);

  Future<void> deleteBudgetCategory(String walletId, String categoryId);

  /// Giao dịch trong [year, month] (theo local), dùng cho tổng chi theo danh mục.
  Stream<List<TransactionModel>> watchTransactionsForMonth({
    required String userId,
    required int year,
    required int month,
  });
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  BudgetRemoteDataSourceImpl({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _categoriesCol(String walletId) {
    return firestore
        .collection('wallets')
        .doc(walletId)
        .collection('categories');
  }

  @override
  Stream<List<CategoryModel>> watchBudgetCategories(
    String walletId, {
    int? month,
    int? year,
  }) {
    Query<Map<String, dynamic>> query = _categoriesCol(walletId);

    if (month != null) query = query.where('month', isEqualTo: month);
    if (year != null) query = query.where('year', isEqualTo: year);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) => CategoryModel.fromJson({
              ...doc.data(),
              'id': doc.id,
              'walletId': walletId,
            }),
          )
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  @override
  Future<void> upsertBudgetCategory(CategoryModel category) async {
    final col = _categoriesCol(category.walletId);
    final docRef = category.id.isEmpty ? col.doc() : col.doc(category.id);

    final data = Map<String, dynamic>.from(category.toJson());
    data['id'] = docRef.id;
    data['walletId'] = category.walletId;
    if (category.id.isEmpty) {
      data['currentSpent'] = 0;
    }
    await docRef.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteBudgetCategory(String walletId, String categoryId) async {
    await _categoriesCol(walletId).doc(categoryId).delete();
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsForMonth({
    required String userId,
    required int year,
    required int month,
  }) {
    final start = DateTime(year, month, 1);
    final endExclusive = DateTime(year, month + 1, 1);

    return firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data(),
            );
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            } else if (data['timestamp'] == null) {
              data['timestamp'] = DateTime.now().toIso8601String();
            }
            return TransactionModel.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }
}
