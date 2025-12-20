import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/colors.dart';
import '../../../constants/image_strings.dart';
import '../../../constants/sizes.dart';
import '../../../features/presentation/blocs/login/login_bloc.dart';
import '../../../features/presentation/blocs/login/login_event.dart';
import '../../../features/presentation/blocs/login/login_state.dart';
import '../../../routes/router.gr.dart';
import '../../../utils/popups/loaders.dart';
import '../../../utils/utils.dart';

class TSocialButtons extends StatelessWidget {
  const TSocialButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginWithGoogleSuccess) {
          Utils.setIsLoggedIn(true);
          AutoRouter.of(context).replace(const NavigationMenuRoute());
          
        }

        if (state is LoginWithGoogleFailure) {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Đăng nhập Google thất bại',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: TColors.grey),
                borderRadius: BorderRadius.circular(100),
              ),
              child: IconButton(
                onPressed: () => context.read<LoginBloc>().add(LoginWithGoogleSubmitted()),
                icon: const Image(
                  width: TSizes.iconMd,
                  height: TSizes.iconMd,
                  image: AssetImage(TImages.google),
                ),
              ),
            ),
            const SizedBox(
              width: TSizes.spaceBtwItems,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: TColors.grey),
                borderRadius: BorderRadius.circular(100),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Image(
                  width: TSizes.iconMd,
                  height: TSizes.iconMd,
                  image: AssetImage(TImages.facebook),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
