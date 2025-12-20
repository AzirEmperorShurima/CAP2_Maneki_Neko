import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/routes/router.gr.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:finance_management_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/loading/loading/loading.dart';
import '../../../../../constants/colors.dart';
import '../../../../../constants/sizes.dart';
import '../../../../../constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../../utils/validators/validation.dart';
import '../../../blocs/login/login_bloc.dart';
import '../../../blocs/login/login_event.dart';
import '../../../blocs/login/login_state.dart';

class TLoginForm extends StatefulWidget {
  const TLoginForm({super.key});

  @override
  State<TLoginForm> createState() => _TLoginFormState();
}

class _TLoginFormState extends State<TLoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool rememberMe = true;
  bool hidePassword = true;

  _login() {
    if (formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
            LoginSubmitted(
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
    THelperFunctions.isDarkMode(context);

    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          Utils.setIsLoggedIn(true);
          AutoRouter.of(context).replace(const NavigationMenuRoute());
        }

        if (state is LoginFailure) {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Đăng nhập thất bại',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        return Form(
          key: formKey,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections),
            child: Column(
              children: [
                // Email
                TextFormField(
                  controller: emailController,
                  validator: (value) => TValidator.validateEmail(value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.direct_right),
                    labelText: TTexts.email,
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwInputFields),

                // Password
                TextFormField(
                  controller: passwordController,
                  validator: (value) =>
                      TValidator.validateEmptyText('Mật khẩu', value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Iconsax.password_check),
                    labelText: TTexts.password,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                      icon:
                          Icon(hidePassword ? Iconsax.eye_slash : Iconsax.eye),
                    ),
                  ),
                  obscureText: hidePassword,
                ),

                const SizedBox(height: TSizes.spaceBtwInputFields / 2),

                // Remember Me & Forget Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember Me
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            setState(() {
                              rememberMe = value!;
                            });
                          },
                        ),
                        const Text(TTexts.rememberMe),
                      ],
                    ),

                    // Forget Password
                    TextButton(
                      onPressed: () {},
                      child: const Text(TTexts.forgetPassword,
                          style: TextStyle(color: TColors.primary)),
                    ),
                  ],
                ),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: TColors.primary,
                      elevation: 2,
                    ),
                    onPressed: () => _login(),
                    child: state is LoginLoading
                        ? TLoadingSpinkit.loadingButton
                        : Text(TTexts.signIn),
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        AutoRouter.of(context).push(const SignUpScreenRoute()),
                    child: const Text(TTexts.createAccount),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
