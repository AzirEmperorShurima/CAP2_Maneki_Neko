
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/widgets/buttons/social_buttons.dart';
import '../../../../common/widgets/dividers/form_divider.dart';
import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';
import '../../blocs/sign_up/signup_bloc.dart';
import '../../blocs/sign_up/signup_state.dart';
import 'widgets/signup_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupBloc, SignupState>(
      // listenWhen: (previous, current) => current is SignupActionState,
      // buildWhen: (previous, current) => current is !SignupActionState,
      listener: (context, state) {
        // if (state is SignupLoadingActionState) {
        //   TFullScreenLoader.openLoadingDialog(context, 'Creating account, please wait a moment...', Assets.animations141594AnimationOfDocer);
        // } else if (state is SignupErrorActionState) {
        //   TFullScreenLoader.stopLoading(context);
        //   TLoaders.errorSnackBar(context, title: 'Error', message: state.message);
        // }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(TTexts.signupTitle, style: Theme.of(context).textTheme.headlineMedium),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Form
                const TSignupForm(),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Divider
                TFormDivider(dividerText: TTexts.orSignUpWith),
                const SizedBox(height: TSizes.spaceBtwItems),

                //Social Buttons
                const TSocialButtons(),
              ],
            ),
          ),
        );
      },
    );
  }
}
