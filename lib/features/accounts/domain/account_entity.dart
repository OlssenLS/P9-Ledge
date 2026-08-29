import '../../../core/domain/enums.dart';

class AccountEntity {
  final int id;
  final String name;
  final AccountType type;
  final double startingBalance;
  final double currentBalance;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.startingBalance,
    required this.currentBalance,
  });

  AccountEntity copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? startingBalance,
    double? currentBalance,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startingBalance: startingBalance ?? this.startingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
