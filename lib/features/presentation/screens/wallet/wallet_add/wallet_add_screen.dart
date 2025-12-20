import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/common/widgets/containers/bordered_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/containers/bordered_text_field.dart';
import '../../../../../common/widgets/text/overflow_marquee_text.dart';
import '../../../../../common/widgets/wallet_picker/wallet_type_picker_bottom_sheet.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/app_spacing.dart';
import '../../../../../constants/colors.dart';
import '../../../../../utils/popups/loaders.dart';
import '../../../../domain/entities/wallet_model.dart';
import '../../../blocs/wallet/wallet_bloc.dart';

@RoutePage()
class WalletAddScreen extends StatefulWidget {
  final WalletModel? wallet;

  const WalletAddScreen({super.key, this.wallet});

  @override
  State<WalletAddScreen> createState() => _WalletAddScreenState();
}

class _WalletAddScreenState extends State<WalletAddScreen> {
  String? selectedType;
  String? selectedTypeName;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? _walletId;

  @override
  void initState() {
    super.initState();
    
    // Nếu có wallet (edit mode), load dữ liệu vào form
    if (widget.wallet != null) {
      final wallet = widget.wallet!;
      _walletId = wallet.id;
      nameController.text = wallet.name ?? '';
      balanceController.text = (wallet.balance ?? 0).toString();
      descriptionController.text = wallet.description ?? '';
      selectedType = wallet.type;
      // Có thể cần map type sang typeName nếu có
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void createWallet() {
      if (nameController.text.isEmpty || balanceController.text.isEmpty) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng nhập tên ví tiền và số tiền',
        );
        return;
      }

      if (double.tryParse(balanceController.text) == null) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Số tiền không hợp lệ',
        );
        return;
      }

      if (selectedType == null) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng chọn loại ví tiền',
        );
        return;
      }

      // Nếu có walletId thì update, ngược lại thì create
      if (_walletId != null && _walletId!.isNotEmpty) {
        // Update wallet
        context.read<WalletBloc>().add(
              UpdateWalletSubmitted(
                walletId: _walletId!,
                name: nameController.text,
                balance: double.tryParse(balanceController.text),
                description: descriptionController.text,
                type: selectedType,
              ),
            );
      } else {
        // Create wallet
        context.read<WalletBloc>().add(
              CreateWalletSubmitted(
                name: nameController.text,
                balance: double.tryParse(balanceController.text),
                description: descriptionController.text,
                type: selectedType,
              ),
            );
      }
    }

    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WalletCreated || state is WalletUpdated) {
          final isUpdate = state is WalletUpdated;
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Thành công',
            message: isUpdate ? 'Cập nhật ví tiền thành công' : 'Tạo ví tiền thành công',
          );
          context.read<WalletBloc>().add(LoadWalletsSubmitted());
          Navigator.of(context).pop();
        } else if (state is WalletCreateFailure || state is WalletUpdateFailure) {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Lỗi',
            message: state is WalletCreateFailure
                ? state.message
                : (state as WalletUpdateFailure).message,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is WalletCreating || state is WalletUpdating;
        return Scaffold(
          appBar: TAppBar(
            title: Text(
                widget.wallet != null ? 'Sửa ví tiền' : 'Tạo ví tiền',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: TColors.white)),
            centerTitle: true,
            showBackArrow: true,
            leadingIconColor: TColors.white,
            actions: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TColors.white,
                  ),
                )
              else
                IconButton(
                  onPressed: createWallet,
                  icon: const Icon(Icons.check, size: 25, color: TColors.white),
                ),
            ],
            backgroundColor: TColors.primary,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: AppPadding.a8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.h8,
                  BorderedTextField(
                    title: 'Tên ví tiền',
                    hintText: 'Nhập tên ví tiền',
                    controller: nameController,
                    assetIcon: 'assets/images/icons/wallet.png',
                    isRequired: true,
                    borderRadius: 8,
                  ),
                  AppSpacing.h16,
                  BorderedTextField(
                    title: 'Số tiền',
                    hintText: 'Nhập số tiền',
                    controller: balanceController,
                    assetIcon: 'assets/images/icons/money.png',
                    isRequired: true,
                    borderRadius: 8,
                  ),
                  AppSpacing.h16,
                  GestureDetector(
                    onTap: () {
                      WalletTypePickerBottomSheet.show(
                        context: context,
                        selectedType: selectedType,
                        onTypeSelected: (type, typeName) {
                          setState(() {
                            selectedType = type;
                            selectedTypeName = typeName;
                          });
                        },
                      );
                    },
                    child: BorderedContainer(
                      padding: const EdgeInsets.only(
                          left: 16, right: 8, top: 16, bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset('assets/images/icons/type_wallet.png',
                                  height: 40, width: 40),
                              AppSpacing.w16,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Loại ví tiền',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  if (selectedTypeName != null) ...[
                                    AppSpacing.h4,
                                    Text(
                                      selectedTypeName!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_right,
                              size: 30, color: TColors.primary),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.h16,
                  BorderedContainer(
                    padding: const EdgeInsets.only(
                        left: 16, right: 8, top: 16, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/icons/select_icon.png',
                                height: 40, width: 40),
                            AppSpacing.w16,
                            Text('Biểu tượng',
                                style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                        const Icon(Icons.arrow_right,
                            size: 30, color: TColors.primary),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  BorderedContainer(
                    padding: const EdgeInsets.only(
                        left: 16, right: 8, top: 16, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Image.asset('assets/images/icons/eye_check.png',
                                  height: 40, width: 40),
                              AppSpacing.w16,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sử dụng trong sổ cái hiện tại',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    AppSpacing.h4,
                                    OverflowMarqueeText(
                                      text:
                                          'Được hiển thị trong sổ cái hiện tại và bao gồm trong tài sản',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.w8,
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: true,
                            onChanged: (value) {},
                            activeColor: TColors.white,
                            activeTrackColor: TColors.primary,
                            inactiveTrackColor: TColors.white,
                            inactiveThumbColor: TColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  BorderedContainer(
                    padding: const EdgeInsets.only(
                        left: 16, right: 8, top: 16, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Image.asset('assets/images/icons/savings.png',
                                  height: 40, width: 40),
                              AppSpacing.w16,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bao gồm như tài sản',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    AppSpacing.h4,
                                    OverflowMarqueeText(
                                      text:
                                          'Bao gồm trong tài sản hoặc nợ phải trả trong thống kê',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.w8,
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: true,
                            onChanged: (value) {},
                            activeColor: TColors.white,
                            activeTrackColor: TColors.primary,
                            inactiveTrackColor: TColors.white,
                            inactiveThumbColor: TColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  BorderedTextField(
                    title: 'Ghi chú',
                    hintText: 'Nhập ghi chú',
                    controller: descriptionController,
                    assetIcon: 'assets/images/icons/note.png',
                    isRequired: false,
                    borderRadius: 8,
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
