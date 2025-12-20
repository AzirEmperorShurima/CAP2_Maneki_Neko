import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../constants/app_border_radius.dart';
import '../../../constants/app_padding.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/colors.dart';
import '../../../features/presentation/blocs/family/family_bloc.dart';
import '../../../utils/popups/loaders.dart';

class JoinFamilyBottomSheet extends StatefulWidget {
  const JoinFamilyBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return TLoaders.bottomSheet(
      context: context,
      heightPercentage: 0.4,
      borderRadius: AppBorderRadius.md,
      child: const JoinFamilyBottomSheet(),
    );
  }

  @override
  State<JoinFamilyBottomSheet> createState() => _JoinFamilyBottomSheetState();
}

class _JoinFamilyBottomSheetState extends State<JoinFamilyBottomSheet> {
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mã gia đình';
    }
    if (value.length < 4) {
      return 'Mã gia đình không hợp lệ';
    }
    return null;
  }

  void _handleJoin() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      context.read<FamilyBloc>().add(
            JoinFamilySubmitted(familyCode: _codeController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state is FamilyJoined) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop();
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Thành công',
            message: 'Đã tham gia gia đình thành công',
          );
        } else if (state is FamilyJoinFailure) {
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
                        'Tham gia gia đình',
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
                    'Nhập mã mời để tham gia gia đình',
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
                      controller: _codeController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã mời',
                        prefixIcon:
                            const Icon(Iconsax.code, color: TColors.primary),
                        border: InputBorder.none,
                        contentPadding: AppPadding.a8,
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: TColors.darkGrey),
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                      validator: _validateCode,
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
                onPressed: _isLoading ? null : _handleJoin,
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
                        'Tham gia',
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
