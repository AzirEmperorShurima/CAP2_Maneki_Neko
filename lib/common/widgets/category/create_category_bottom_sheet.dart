import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/domain/entities/category_image_model.dart';
import 'package:finance_management_app/features/domain/entities/category_model.dart';
import 'package:finance_management_app/features/presentation/blocs/category/category_bloc.dart';
import 'package:finance_management_app/utils/helpers/helper_functions.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class CreateCategoryBottomSheet extends StatefulWidget {
  final String? type;

  final Function(CategoryModel category)? onCategoryCreated;

  const CreateCategoryBottomSheet({
    super.key,
    this.type,
    this.onCategoryCreated,
  });

  static Future<void> show({
    required BuildContext context,
    String? type,
    Function(CategoryModel category)? onCategoryCreated,
  }) {
    return TLoaders.bottomSheet(
      context: context,
      heightPercentage: 0.75,
      borderRadius: AppBorderRadius.md,
      child: CreateCategoryBottomSheet(
        type: type,
        onCategoryCreated: onCategoryCreated,
      ),
    );
  }

  @override
  State<CreateCategoryBottomSheet> createState() =>
      _CreateCategoryBottomSheetState();
}

class _CreateCategoryBottomSheetState extends State<CreateCategoryBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedImageUrl;

  @override
  void initState() {
    super.initState();
    // Load images khi mở bottom sheet
    context.read<CategoryBloc>().add(
          LoadCategoryImagesSubmitted(
            folder: 'category_images',
            limit: 100,
          ),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tên danh mục là bắt buộc';
    }
    return null;
  }
  bool _validateImage(String? value) {
    if (value == null || value.trim().isEmpty) {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Ảnh là bắt buộc',
      );
      return false;
    }
    return true;
  }

  void _handleCreate() {
    if ((_formKey.currentState?.validate() ?? false) && _validateImage(_selectedImageUrl)) {
      setState(() => _isLoading = true);
      context.read<CategoryBloc>().add(
            CreateCategorySubmitted(
              name: _nameController.text.trim(),
              type: widget.type,
              image: _selectedImageUrl,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryCreated) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop();
          widget.onCategoryCreated?.call(state.category);
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Thành công',
            message: 'Tạo danh mục thành công',
          );
        } else if (state is CategoryCreateFailure) {
          setState(() => _isLoading = false);
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Lỗi',
            message: state.message,
          );
        }
      },
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          final isDark = THelperFunctions.isDarkMode(context);
          List<CategoryImageModel> images = [];
          bool isLoadingImages = false;

          if (state is CategoryImagesLoading) {
            isLoadingImages = true;
          } else if (state is CategoryImagesLoaded) {
            images = state.images;
          }

          return Padding(
            padding: AppPadding.a16,
            child: Column(
              children: [
                /// ===== Header =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tạo danh mục mới',
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

                /// ===== Content scroll =====
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Tên danh mục
                          Text(
                            'Nhập tên danh mục',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDark ? TColors.lightGrey : TColors.darkerGrey,
                                ),
                          ),
                          AppSpacing.h8,
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? TColors.darkContainer : TColors.softGrey,
                              borderRadius: AppBorderRadius.md,
                            ),
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Ví dụ: Mua thuốc',
                                prefixIcon: Icon(
                                  Iconsax.category,
                                  color: TColors.primary,
                                ),
                                border: InputBorder.none,
                                contentPadding: AppPadding.a8,
                              ),
                              validator: _validateName,
                            ),
                          ),

                          AppSpacing.h24,

                          /// Chọn ảnh

                          if (isLoadingImages)
                            const Center(child: CircularProgressIndicator())
                          else if (images.isNotEmpty)
                            SizedBox(
                              height: 320,
                              child: GridView.builder(
                                padding: const EdgeInsets.only(top: 8, bottom: 50, left: 8, right: 8),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  final image = images[index];
                                  final isSelected =
                                      _selectedImageUrl == image.url;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImageUrl = image.url;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: AppBorderRadius.sm,
                                        border: Border.all(
                                          color: isSelected
                                              ? TColors.primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      padding: AppPadding.a16,
                                      child: ClipRRect(
                                        borderRadius: AppBorderRadius.sm,
                                        child: Image.network(
                                          image.thumbnail ?? image.url ?? '',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              padding: AppPadding.h16,
                              decoration: BoxDecoration(
                                color: isDark ? TColors.darkContainer : TColors.softGrey,
                                borderRadius: AppBorderRadius.md,
                              ),
                              child: Center(
                                child: Text(
                                  'Không có ảnh',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: isDark ? TColors.lightGrey : TColors.darkerGrey),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                /// ===== Button cố định dưới đáy =====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.md,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Tạo danh mục',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
