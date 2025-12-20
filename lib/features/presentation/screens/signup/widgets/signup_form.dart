import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/loading/loading/loading.dart';
import '../../../../../constants/colors.dart';
import '../../../../../constants/sizes.dart';
import '../../../../../constants/text_strings.dart';
import '../../../../../routes/router.gr.dart';
import '../../../../../utils/popups/loaders.dart';
import '../../../../../utils/validators/validation.dart';
import '../../../blocs/sign_up/signup_bloc.dart';
import '../../../blocs/sign_up/signup_event.dart';
import '../../../blocs/sign_up/signup_state.dart';
import 'signup_terms_conditions_checkbox.dart';

class TSignupForm extends StatefulWidget {
  const TSignupForm({super.key});

  @override
  State<TSignupForm> createState() => _TSignupFormState();
}

class _TSignupFormState extends State<TSignupForm> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool hidePassword = true;

  bool checkPrivacyPolicy = false;

  void _signup() {
    if (formKey.currentState!.validate()) {
      if (!checkPrivacyPolicy) {
        TLoaders.showNotification(
          context,
          type: NotificationType.warning,
          title: 'Chấp nhận Chính sách bảo mật',
          message: 'Vui lòng chấp nhận điều khoản để tiếp tục.',
        );
        return;
      }

      context.read<SignupBloc>().add(
            SignupSubmitted(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            ),
          );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          Utils.setIsLoggedIn(true);
          AutoRouter.of(context).replace(const NavigationMenuRoute());
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Thành công',
            message: 'Tạo tài khoản thành công',
          );
        }
        if (state is SignupFailure) {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Đăng ký thất bại',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        return Form(
          key: formKey,
          child: Column(
            children: [
              // Email
              TextFormField(
                controller: emailController,
                validator: (value) => TValidator.validateEmail(value),
                decoration: const InputDecoration(
                  labelText: TTexts.email,
                  prefixIcon: Icon(Iconsax.direct),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwInputFields),

              // Password
              TextFormField(
                controller: passwordController,
                validator: (value) => TValidator.validatePassword(value),
                obscureText: hidePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.password_check),
                  labelText: TTexts.password,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                    icon: Icon(hidePassword ? Iconsax.eye_slash : Iconsax.eye),
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Terms & Conditions Checkbox
              TTermsAndConditionCheckbox(
                value: checkPrivacyPolicy,
                onChanged: (value) {
                  setState(() {
                    checkPrivacyPolicy = value;
                  });
                },
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: TColors.primary,
                    elevation: 5,
                    shadowColor: TColors.primary.withOpacity(0.5),
                  ),
                  onPressed: _signup,
                  child: state is SignupLoading
                      ? TLoadingSpinkit.loadingButton
                      : const Text(TTexts.createAccount),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
