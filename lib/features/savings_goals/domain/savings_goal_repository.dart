import '../../../core/database/app_database.dart';

class SavingsGoalWithDetails {
  final SavingsGoal goal;
  final Account? linkedAccount;
  final List<SavingsContribution> contributions;

  SavingsGoalWithDetails({
    required this.goal,
    this.linkedAccount,
    this.contributions = const [],
  });

  int get remainingCents => goal.targetAmount - goal.currentAmount;
  double get progressPercentage => goal.targetAmount > 0
      ? ((goal.currentAmount / goal.targetAmount) * 100).clamp(0.0, 100.0)
      : 0.0;
}

abstract class SavingsGoalRepository {
  Stream<List<SavingsGoalWithDetails>> watchGoals();
  Future<void> createGoal({
    required String name,
    required int targetAmountCents,
    required DateTime targetDate,
    required int monthlyContributionTargetCents,
    String? linkedAccountId,
    String? description,
  });
  Future<void> addContribution({
    required String goalId,
    required int amountCents,
    String? sourceAccountId,
    String? notes,
  });
  Future<void> deleteGoal(String id);
}
