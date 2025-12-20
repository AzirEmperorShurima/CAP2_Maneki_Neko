import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../common/widgets/buttons/social_buttons.dart';
import '../../../../common/widgets/dividers/form_divider.dart';
import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';

@RoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {    
    return const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: TSizes.appBarHeight,
          left: TSizes.defaultSpace,
          right: TSizes.defaultSpace,
          bottom: TSizes.defaultSpace,
        ),
        child: Column(
          children: [
            // Logo, Title & Sub-Title
            TLoginHeader(),

            // Form
            TLoginForm(),

            // Divider
            TFormDivider(dividerText: TTexts.orSignInWith),
            SizedBox(height: TSizes.spaceBtwItems),

            // Footer
            TSocialButtons()
          ],
        ),
      ),
    );
  }
}
