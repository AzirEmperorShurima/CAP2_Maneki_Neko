import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../constants/app_border_radius.dart';
import '../../../constants/app_padding.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/colors.dart';
import '../../../features/presentation/blocs/family/family_bloc.dart';
import '../../../utils/popups/loaders.dart';
import '../../../utils/validators/validation.dart';

class InviteFamilyBottomSheet extends StatefulWidget {
  const InviteFamilyBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return TLoaders.bottomSheet(
      context: context,
      heightPercentage: 0.4,
      borderRadius: AppBorderRadius.md,
      child: const InviteFamilyBottomSheet(),
    );
  }

  @override
  State<InviteFamilyBottomSheet> createState() =>
      _InviteFamilyBottomSheetState();
}

class _InviteFamilyBottomSheetState extends State<InviteFamilyBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final error = TValidator.validateEmail(value);
    if (error != null) {
      return error.replaceAll('is required', 'là bắt buộc')
          .replaceAll('Invalid email address', 'Email không hợp lệ');
    }
    return null;
  }

  void _handleInvite() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      context.read<FamilyBloc>().add(
            InviteToFamilySubmitted(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state is FamilyInvited) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop();
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Thành công',
            message: 'Đã gửi lời mời đến ${state.email}',
          );
        } else if (state is FamilyInviteFailure) {
          setState(() => _isLoading = false);
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Lỗi',
            message: state.message,
          );
        }
      },
      child: Padding(
        padding: AppPadding.a16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mời thành viên',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Iconsax.close_circle),
                      ),
                    ],
                  ),
                  AppSpacing.h16,
                  Text(
                    'Nhập email để gửi lời mời tham gia gia đình',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TColors.darkerGrey,
                        ),
                  ),
                  AppSpacing.h16,
                  Container(
                    decoration: BoxDecoration(
                      color: TColors.softGrey,
                      borderRadius: AppBorderRadius.md,
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'example@email.com',
                        prefixIcon: const Icon(Iconsax.sms, color: TColors.primary),
                        border: InputBorder.none,
                        contentPadding: AppPadding.a8,
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: TColors.darkGrey),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  padding: AppPadding.v16,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.md,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Gửi lời mời',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
