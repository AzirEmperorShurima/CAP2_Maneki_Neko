import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/presentation/blocs/wallet/wallet_bloc.dart';
import 'package:finance_management_app/utils/loaders/animation_loader.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/category_icon/category_icon.dart';
import '../../../../common/widgets/text/price_text.dart';
import '../../../../constants/app_border_radius.dart';
import '../../../../constants/app_padding.dart';
import '../../../../constants/app_spacing.dart';
import '../../../../constants/assets.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/loaders/chat_loading.dart';
import '../../../domain/entities/bill_image_model.dart';
import '../../../domain/entities/category_model.dart';
import '../../../domain/entities/message_model.dart';
import '../../blocs/analysis/analysis_bloc.dart';
import '../../blocs/budget/budget_bloc.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';

@RoutePage()
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  
  // Audio player cho voice messages
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingPath;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Xin chào!👋 Hãy bắt đầu thêm giao dịch của bạn tại đây nhé',
      'isUser': false,
      'time': DateTime.now(),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Scroll xuống tin nhắn đầu tiên sau khi build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    // Listen to audio player state changes (với error handling)
    _audioPlayer.positionStream.listen(
      (position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      },
      onError: (error) {
        debugPrint('Audio position stream error: $error');
      },
    );
    
    _audioPlayer.durationStream.listen(
      (duration) {
        if (mounted) {
          setState(() {
            _totalDuration = duration ?? Duration.zero;
          });
        }
      },
      onError: (error) {
        debugPrint('Audio duration stream error: $error');
      },
    );
    
    _audioPlayer.playerStateStream.listen(
      (state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _currentlyPlayingPath = null;
              _currentPosition = Duration.zero;
            }
          });
        }
      },
      onError: (error) {
        debugPrint('Audio player state stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    try {
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
    super.dispose();
  }

  String get _recordDuration {
    final m = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_recordSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();

    // Thêm tin nhắn của user vào danh sách
    setState(() {
      _messages.add({
        'text': messageText,
        'isUser': true,
        'time': DateTime.now(),
      });
    });

    // Dispatch event để gửi tin nhắn đến API
    context.read<ChatBloc>().add(SendMessageSubmitted(messageText));

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    // Hiển thị bottom sheet với 2 lựa chọn
    TLoaders.bottomSheet(
      context: context,
      borderRadius: AppBorderRadius.md,
      child: Padding(
        padding: AppPadding.a16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSpacing.h8,
            Text(
              'Chọn ảnh',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.h16,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Option 1: Chọn từ thư viện
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Iconsax.gallery,
                          size: 30,
                          color: TColors.primary,
                        ),
                      ),
                      AppSpacing.h8,
                      Text(
                        'Thư viện',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Option 2: Chụp ảnh
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Iconsax.camera,
                          size: 30,
                          color: TColors.primary,
                        ),
                      ),
                      AppSpacing.h8,
                      Text(
                        'Camera',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.h16,
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _sendImage(image.path);
      }
    } catch (e) {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Không thể chọn ảnh từ thư viện: $e',
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        _sendImage(image.path);
      }
    } catch (e) {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Không thể chụp ảnh: $e',
      );
    }
  }

  void _sendImage(String imagePath) {
    // Thêm tin nhắn của user vào danh sách
    setState(() {
      _messages.add({
        'text': 'Đã gửi ảnh',
        'isUser': true,
        'time': DateTime.now(),
        'imagePath': imagePath,
      });
    });

    // Dispatch event để gửi ảnh đến API
    context.read<ChatBloc>().add(
          SendImageSubmitted(
            filePath: imagePath,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          ),
        );

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _recordVoice() async {
    try {
      if (_isRecording) {
        // Dừng ghi âm và gửi
        await _stopRecording();
      } else {
        // Bắt đầu ghi âm
        await _startRecording();
      }
    } catch (e) {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Không thể ghi âm: $e',
      );
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();

    if (!hasPermission) {
      final status = await Permission.microphone.request();

      if (!status.isGranted) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Cần quyền microphone',
          message: 'Vui lòng bật quyền ghi âm trong cài đặt',
        );
        await openAppSettings();
        return;
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _recordTimer?.cancel();
    _recordSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordSeconds++;
      });
    });

    setState(() {
      _isRecording = true;
      _recordingPath = path;
    });
  }

  Future<void> _stopRecording({bool send = true}) async {
    if (!_isRecording || _recordingPath == null) return;

    _recordTimer?.cancel();

    // Lưu duration trước khi reset
    final duration = _recordSeconds;

    // Dừng ghi âm
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    if (!send || path == null) {
      _recordingPath = null;
      return;
    }

    if (path.isNotEmpty) {
      // Kiểm tra file có tồn tại không
      final file = File(path);
      if (await file.exists()) {
        // Thêm tin nhắn của user vào danh sách
        setState(() {
          _messages.add({
            'isUser': true,
            'time': DateTime.now(),
            'voicePath': path,
            'duration': duration,
          });
        });

        // Dispatch event để gửi voice đến API
        context.read<ChatBloc>().add(
              SendVoiceSubmitted(
                filePath: path,
                message: _messageController.text.trim().isEmpty
                    ? null
                    : _messageController.text.trim(),
              ),
            );

        _messageController.clear();
        _scrollToBottom();
      } else {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'File ghi âm không tồn tại',
        );
      }
    } else {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Không thể lưu file ghi âm',
      );
    }

    _recordingPath = null;
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position.maxScrollExtent;

      if (animated) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded) {
          // Thêm phản hồi từ bot vào danh sách
          setState(() {
            _messages.add({
              'text': '', // Sẽ hiển thị bằng widget riêng
              'isUser': false,
              'time': DateTime.now(),
              'message': state.message,
            });
          });
          _scrollToBottom();

          context.read<TransactionBloc>().add(RefreshTransactions(
                type: null,
                page: 1,
                limit: 20,
              ));

          context.read<AnalysisBloc>().add(RefreshAnalysis());

          context.read<WalletBloc>().add(RefreshWallets());

          context.read<BudgetBloc>().add(RefreshBudgets());
        } else if (state is ChatFailure) {
          // Hiển thị lỗi
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
          centerTitle: true,
          showBackArrow: true,
          actions: [
            Padding(
              padding: AppPadding.h16,
              child: Icon(Iconsax.lamp_on),
            ),
          ],
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // // Thông báo thời gian chat
            // Padding(
            //   padding: AppPadding.h16.add(AppPadding.v8),
            //   child: Text(
            //     'Cuộc trò chuyện kéo dài 48 giờ',
            //     style: Theme.of(context)
            //         .textTheme
            //         .labelLarge
            //         ?.copyWith(color: TColors.darkGrey),
            //   ),
            // ),
            // Danh sách tin nhắn
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, chatState) {
                  if (chatState is ChatLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppPadding.h16.add(AppPadding.v8),
                    itemCount: _messages.length +
                        2 +
                        (chatState is ChatLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Hiển thị animation loader ở đầu
                        return Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: AppPadding.v8,
                            child: TAnimationLoaderWidget(
                              text: '',
                              message: 'Hôm nay bạn đã chi tiêu những gì?',
                              animation: Assets.animationChatBot,
                              width:
                                  THelperFunctions.screenWidth(context) * 0.5,
                              height:
                                  THelperFunctions.screenHeight(context) * 0.3,
                            ),
                          ),
                        );
                      }

                      // Hiển thị typing indicator khi đang gửi tin nhắn
                      if (chatState is ChatLoading &&
                          index == _messages.length + 1) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: TypingIndicator(),
                        );
                      }

                      // Thêm khoảng trống ở cuối để đẩy nội dung lên
                      final loadingOffset = chatState is ChatLoading ? 1 : 0;
                      if (index == _messages.length + 1 + loadingOffset) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1,
                        );
                      }

                      final message = _messages[index - 1];
                      final isUser = message['isUser'] as bool;
                      final messageModel = message.containsKey('message')
                          ? message['message'] as MessageModel?
                          : null;
                      final messageText = message['text'] as String?;
                      final imagePath = message['imagePath'] as String?;
                      final voicePath = message['voicePath'] as String?;
                      final voiceDuration = message['duration'] as int? ?? 0;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: AppPadding.v4,
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? TColors.primary : TColors.softGrey,
                            borderRadius: isUser
                                ? AppBorderRadius.md.copyWith(
                                    topRight: Radius.zero,
                                  )
                                : AppBorderRadius.md.copyWith(
                                    topLeft: Radius.zero,
                                  ),
                          ),
                          child: isUser
                              ? _buildUserMessage(
                                  context,
                                  messageText: messageText,
                                  imagePath: imagePath,
                                  voicePath: voicePath,
                                  voiceDuration: voiceDuration,
                                )
                              : messageModel != null
                                  ? _buildBotMessage(context, messageModel)
                                  : Text(
                                      messageText ?? 'Đã nhận được phản hồi',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: TColors.black,
                                          ),
                                    ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Phần nhập tin nhắn
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              decoration: BoxDecoration(
                color: THelperFunctions.isDarkMode(context)
                    ? TColors.darkContainer
                    : TColors.white,
                boxShadow: [
                  BoxShadow(
                    color: TColors.grey,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _isRecording ? _buildRecordingBar() : _buildInputBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = THelperFunctions.isDarkMode(context);
    return Row(
      children: [
        IconButton(
          onPressed: _pickImage,
          icon: const Icon(Iconsax.camera, color: TColors.primary, size: 28),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? TColors.darkerGrey : TColors.softGrey,
              borderRadius: AppBorderRadius.md,
            ),
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Bữa sáng 100k, mua sắm 500k',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: TColors.darkGrey),
                border: InputBorder.none,
                contentPadding: AppPadding.a8,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        IconButton(
          onPressed: _recordVoice,
          icon: const Icon(Iconsax.microphone, color: TColors.primary, size: 28),
        ),
        IconButton(
          onPressed: _sendMessage,
          icon: const Icon(Iconsax.send_1, color: TColors.primary, size: 28),
        ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    final isDark = THelperFunctions.isDarkMode(context);
    return Row(
      children: [
        /// Cancel
        IconButton(
          onPressed: () async {
            await _stopRecording(send: false);
          },
          icon: const Icon(Iconsax.close_circle, color: Colors.red, size: 28),
        ),

        /// Red dot + timer
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.w8,
            Text(
              _recordDuration,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),

        AppSpacing.w12,

        /// Fake waveform
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? TColors.darkerGrey : TColors.softGrey,
              borderRadius: AppBorderRadius.md,
            ),
            child: Center(
              child: Text(
                '🎙️ Đang ghi âm...',
                style: TextStyle(
                  color: isDark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
            ),
          ),
        ),

        /// Send
        IconButton(
          onPressed: () => _stopRecording(),
          icon: const Icon(Iconsax.tick_circle, color: TColors.primary, size: 30),
        ),
      ],
    );
  }

  String _cleanMessage(String? message) {
    if (message == null || message.isEmpty) return '';

    // Loại bỏ [object Promise]
    String cleaned = message.replaceAll(RegExp(r'\[object Promise\]'), '');

    // Xử lý markdown formatting: **text** thành text đậm (tạm thời chỉ loại bỏ **)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*'), '');

    // Trim để loại bỏ khoảng trắng thừa
    cleaned = cleaned.trim();

    return cleaned;
  }

  Widget _buildBotMessage(BuildContext context, MessageModel? messageModel) {
    if (messageModel == null) {
      return Text(
        'Đã nhận được phản hồi',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TColors.black,
            ),
      );
    }

    final transaction = messageModel.transaction;
    final jokeMessage = messageModel.jokeMessage;
    final message = messageModel.message;
    final billImage = messageModel.billImage;
    final cleanedMessage = _cleanMessage(message);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (cleanedMessage.isNotEmpty)
          Text(
            cleanedMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TColors.black,
                ),
          ),
        // Hiển thị bill image nếu có
        if (billImage != null &&
            billImage.url != null &&
            billImage.url!.isNotEmpty) ...[
          AppSpacing.h8,
          _buildBillImage(context, billImage),
        ],
        // Hiển thị transaction info nếu có
        AppSpacing.h8,
        if (transaction != null) ...[
          _buildTransactionInfo(context, transaction),
          if (jokeMessage != null) AppSpacing.h8,
        ],
        // Hiển thị joke message nếu có
        if (jokeMessage != null)
          Text(
            jokeMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TColors.black,
                ),
          ),
      ],
    );
  }

  Widget _buildTransactionInfo(BuildContext context, dynamic transaction) {
    // Transaction có thể là TransactionModel hoặc Map (từ API response)
    num? amountValue;
    String? categoryName;
    String? type;
    num? confidence;
    CategoryModel? categoryModel;

    if (transaction is Map) {
      // Xử lý Map (từ API response trực tiếp)
      amountValue = transaction['amount'] as num?;
      final category = transaction['category'];
      // Category có thể là string hoặc object (từ API response)
      if (category is String) {
        categoryName = category;
        categoryModel = CategoryModel(name: category);
      } else if (category is Map && category['name'] != null) {
        categoryName = category['name'] as String?;
        categoryModel = CategoryModel(name: categoryName);
      }
      type = transaction['type'] as String?;
      confidence = transaction['confidence'] as num?;
    } else {
      // Xử lý TransactionModel
      amountValue = transaction.amount;
      categoryName = transaction.category?.name;
      categoryModel = transaction.category;
      type = transaction.type;
      confidence = null;
    }

    final amount = amountValue?.toInt() ?? 0;

    final isExpense = type == 'expense';
    final amountColor = isExpense ? Colors.red : Colors.green;

    return Container(
      padding: AppPadding.a8,
      decoration: const BoxDecoration(
        color: TColors.white,
        borderRadius: AppBorderRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: "Đã ghi giao dịch"
          Text('Đã ghi nhận: ${isExpense ? 'Chi tiêu' : 'Thu nhập'}',
              style: Theme.of(context).textTheme.titleSmall),
          if (categoryName != null && categoryName.isNotEmpty) ...[
            AppSpacing.h8,
            Row(
              children: [
                // Category Icon
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: AppBorderRadius.sm,
                    color: TColors.primary.withOpacity(0.1),
                  ),
                  padding: AppPadding.a4,
                  child: Center(
                    child: CategoryIcon(
                      category: categoryModel,
                      transactionType: type,
                      size: 50,
                    ),
                  ),
                ),
                AppSpacing.w8,
                // Category Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh mục',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: TColors.darkGrey,
                            ),
                      ),
                      Text(
                        categoryName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: TColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),

                PriceText(
                  amount: amount.toString(),
                  color: amountColor,
                ),
              ],
            ),
          ],
          if (confidence != null) ...[
            AppSpacing.h4,
            Text(
              'Độ chính xác: ${(confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TColors.darkGrey,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserMessage(
    BuildContext context, {
    String? messageText,
    String? imagePath,
    String? voicePath,
    int voiceDuration = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hiển thị ảnh nếu có
        if (imagePath != null && imagePath.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: InteractiveViewer(
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: AppBorderRadius.sm,
              child: Image.file(
                File(imagePath),
                width: 200,
                height: 300,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  color: TColors.softGrey,
                  child: const Icon(
                    Icons.error,
                    color: TColors.darkGrey,
                  ),
                ),
              ),
            ),
          ),
          if (messageText != null && messageText.isNotEmpty) AppSpacing.h8,
        ],
        // Hiển thị voice nếu có
        if (voicePath != null && voicePath.isNotEmpty) ...[
          _buildVoiceMessage(
            context,
            voicePath,
            voiceDuration,
          ),
          if (messageText != null && messageText.isNotEmpty) AppSpacing.h8,
        ],
        // Hiển thị text nếu có
        if (messageText != null && messageText.isNotEmpty)
          Text(
            messageText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TColors.white,
                ),
          ),
      ],
    );
  }

  Future<void> _toggleVoicePlayback(String path) async {
    try {
      if (_currentlyPlayingPath == path && _isPlaying) {
        // Pause current audio
        await _audioPlayer.pause();
      } else if (_currentlyPlayingPath == path && !_isPlaying) {
        // Resume current audio
        await _audioPlayer.play();
      } else {
        // Play new audio
        if (_currentlyPlayingPath != null) {
          await _audioPlayer.stop();
        }
        _currentlyPlayingPath = path;
        await _audioPlayer.setFilePath(path);
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error toggling voice playback: $e');
      // Chỉ hiển thị notification nếu không phải MissingPluginException
      if (!e.toString().contains('MissingPluginException')) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Không thể phát audio. Vui lòng rebuild app.',
        );
      }
    }
  }

  Widget _buildVoiceMessage(
    BuildContext context,
    String path,
    int duration,
  ) {
    final isCurrentlyPlaying = _currentlyPlayingPath == path;
    final displayDuration = isCurrentlyPlaying && _totalDuration.inSeconds > 0
        ? _totalDuration.inSeconds
        : duration;
    
    final m = (displayDuration ~/ 60).toString().padLeft(2, '0');
    final s = (displayDuration % 60).toString().padLeft(2, '0');
    
    // Calculate progress for waveform
    final progress = isCurrentlyPlaying && _totalDuration.inSeconds > 0
        ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => _toggleVoicePlayback(path),
      child: Container(
        padding: AppPadding.a8,
        decoration: BoxDecoration(
          color: TColors.primary.withOpacity(0.9),
          borderRadius: AppBorderRadius.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCurrentlyPlaying && _isPlaying
                  ? Iconsax.pause_circle
                  : Iconsax.play_circle,
              color: Colors.white,
              size: 28,
            ),
            AppSpacing.w8,
            Text(
              isCurrentlyPlaying && _totalDuration.inSeconds > 0
                  ? '${(_currentPosition.inSeconds ~/ 60).toString().padLeft(2, '0')}:${(_currentPosition.inSeconds % 60).toString().padLeft(2, '0')}'
                  : '$m:$s',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white),
            ),
            AppSpacing.w8,
            // Waveform với progress
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 60 * progress,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillImage(BuildContext context, BillImageModel billImage) {
    final imageUrl = billImage.url ?? billImage.thumbnail;

    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Có thể mở full screen image viewer nếu cần
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.sm,
          border: Border.all(color: TColors.softGrey),
        ),
        child: ClipRRect(
          borderRadius: AppBorderRadius.sm,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: TColors.softGrey,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: TColors.softGrey,
              child: const Icon(Icons.error, color: TColors.darkGrey),
            ),
          ),
        ),
      ),
    );
  }
}
