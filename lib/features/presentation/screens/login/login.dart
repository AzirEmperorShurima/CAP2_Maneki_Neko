import 'package:flutter/material.dart';

import '../../../../common/widgets/buttons/social_buttons.dart';
import '../../../../common/widgets/dividers/form_divider.dart';
import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: TSizes.appBarHeight,
          left: TSizes.defaultSpace,
          right: TSizes.defaultSpace,
          bottom: TSizes.defaultSpace,
        ),
        child: Column(
          children: [
            // Logo, Title & Sub-Title
            const TLoginHeader(),

            // Form
            const TLoginForm(),

            // Divider
            TFormDivider(dividerText: TTexts.orSignInWith),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Footer
            const TSocialButtons()
          ],
        ),
      ),
    );
  }
}
