import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../constants/app_border_radius.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/app_spacing.dart';
import '../../../../../constants/colors.dart';
import '../../../../../features/presentation/blocs/family/family_bloc.dart';
import '../../../../../utils/popups/loaders.dart';

@RoutePage()
class FamilyAddScreen extends StatefulWidget {
  const FamilyAddScreen({super.key});

  @override
  State<FamilyAddScreen> createState() => _FamilyAddScreenState();
}

class _FamilyAddScreenState extends State<FamilyAddScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên gia đình';
    }
    if (value.trim().length < 3) {
      return 'Tên gia đình phải có ít nhất 3 ký tự';
    }
    return null;
  }

  void _handleCreate() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<FamilyBloc>().add(
            CreateFamilySubmitted(name: _nameController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state is FamilyCreated) {
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Thành công',
            message: 'Đã tạo gia đình thành công',
          );
          Navigator.of(context).pop();
        } else if (state is FamilyCreateFailure) {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Lỗi',
            message: state.message,
          );
        }
      },
      child: Scaffold(
        appBar: const TAppBar(
          title: Text('Tạo gia đình mới'),
          showBackArrow: true,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: AppPadding.a16,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.h16,
                Text(
                  'Nhập tên gia đình',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                AppSpacing.h8,
                Text(
                  'Tạo một gia đình mới và trở thành quản lý',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TColors.darkerGrey,
                      ),
                ),
                AppSpacing.h24,
                Container(
                  decoration: BoxDecoration(
                    color: TColors.softGrey,
                    borderRadius: AppBorderRadius.md,
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên gia đình',
                      prefixIcon: Icon(Iconsax.people, color: TColors.primary),
                      border: InputBorder.none,
                      contentPadding: AppPadding.a8,
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: TColors.darkGrey),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    validator: _validateName,
                  ),
                ),
                AppSpacing.h32,
                BlocBuilder<FamilyBloc, FamilyState>(
                  builder: (context, state) {
                    final isLoading = state is FamilyCreating;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          padding: AppPadding.v16,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppBorderRadius.md,
                          ),
                        ),
                        child: isLoading
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
                                'Tạo gia đình',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
