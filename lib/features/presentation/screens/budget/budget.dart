import 'package:flutter/material.dart';

import '../../../../common/api_builder/budget_builder.dart';
import '../../../../common/widgets/card/budget_card.dart';

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BudgetBuilder(
      itemBuilder: (context, budget, index) {
        return BudgetCard(
          budget: budget,
          variant: BudgetCardVariant.full,
        );
      },
    );
  }
}
