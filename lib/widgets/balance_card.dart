import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';

class BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool isNegative;

  const BalanceCard({
    super.key,
    required this.title,
    required this.amount,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.caption(context),
            ),
            Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(amount),
              style: AppTextStyles.bodyBold(context).copyWith(
                fontSize: 15,
                color: isNegative
                    ? AppColors.expenseRed
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
