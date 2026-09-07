import '../../../core/domain/enums.dart';
import '../../categories/domain/category_entity.dart';
import '../../accounts/domain/account_entity.dart';

class TransactionEntity {
  final int id;
  final double amount;
  final TransactionType type;
  final int? categoryId;
  final int accountId;
  final int? toAccountId;
  final String? note;
  final DateTime date;
  
  // Optional relations
  final CategoryEntity? category;
  final AccountEntity? account;
  final AccountEntity? toAccount;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.note,
    required this.date,
    this.category,
    this.account,
    this.toAccount,
  });
}
