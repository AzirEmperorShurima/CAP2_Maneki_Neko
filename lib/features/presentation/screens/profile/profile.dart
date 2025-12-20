import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/profile/t_circular_image.dart';
import '../../../../common/widgets/text/section_heading.dart';
import '../../../../constants/image_strings.dart';
import '../../../../constants/sizes.dart';
import '../../../presentation/blocs/user/user_bloc.dart';
import 'widgets/profile_menu.dart';

@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        final user = state is UserLoaded ? state.user : null;

        return Scaffold(
          appBar: const TAppBar(
            title: Text('Hồ sơ cá nhân'),
            showBackArrow: true,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  // Profile Picture
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        TCircularImage(
                          image:
                              user?.avatar != null && user!.avatar!.isNotEmpty
                                  ? user.avatar!
                                  : TImages.user,
                          width: 80,
                          height: 80,
                          isNetworkImage:
                              user?.avatar != null && user!.avatar!.isNotEmpty,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Thay đổi ảnh đại diện'),
                        ),
                      ],
                    ),
                  ),

                  // Details
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  const Divider(),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Heading Profile Info
                  const TSectionHeading(
                      title: 'Thông tin hồ sơ', showActionButton: false),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  TProfileMenu(
                    title: 'Tên',
                    value: user?.username ?? 'Chưa cập nhật',
                    onTap: () {},
                  ),

                  const SizedBox(height: TSizes.spaceBtwItems),
                  const Divider(),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Heading Personal Info
                  const TSectionHeading(
                      title: 'Thông tin cá nhân', showActionButton: false),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  TProfileMenu(
                    title: 'E-mail',
                    value: user?.email ?? 'Chưa cập nhật',
                    onTap: () {},
                  ),
                  TProfileMenu(
                    title: 'ID',
                    value: user?.id ?? 'Chưa cập nhật',
                    onTap: () {},
                  ),
                  TProfileMenu(
                    title: 'Gia đình',
                    value: user?.family ?? 'Chưa có',
                    onTap: () {},
                  ),
                  TProfileMenu(
                    title: 'Trạng thái',
                    value: user != null ? 'Đang hoạt động' : 'Chưa đăng nhập',
                    onTap: () {},
                  ),

                  const Divider(),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Đóng tài khoản',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
