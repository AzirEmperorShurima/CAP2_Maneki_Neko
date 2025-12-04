import 'package:flutter/material.dart';

import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';

class TTextSaveButton extends StatelessWidget {
  const TTextSaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
      child: Text(
        'Save',
        style: Theme.of(context)
            .textTheme
            .bodyLarge!
            .copyWith(color: TColors.white),
      ),
    );
  }
}
