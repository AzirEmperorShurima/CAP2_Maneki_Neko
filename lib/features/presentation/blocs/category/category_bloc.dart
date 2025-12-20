import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_management_app/features/domain/entities/category_image_model.dart';
import 'package:finance_management_app/features/domain/entities/category_model.dart';
import 'package:finance_management_app/features/domain/repository/category_repository.dart';
import 'package:injectable/injectable.dart';

part 'category_event.dart';
part 'category_state.dart';

@injectable
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc(this.categoryRepository) : super(CategoryInitial()) {
    on<LoadCategoriesSubmitted>(_onLoadCategoriesSubmitted);
    on<LoadCategoryImagesSubmitted>(_onLoadCategoryImagesSubmitted);
    on<ResetCategories>(_onResetCategories);
    on<CreateCategorySubmitted>(_onCreateCategorySubmitted);
  }

  Future<void> _onLoadCategoriesSubmitted(
    LoadCategoriesSubmitted event,
    Emitter<CategoryState> emit,
  ) async {
    // Kiểm tra xem đã có data chưa (chỉ skip nếu đã có data và cùng type)
    // Sau khi reset về CategoryInitial, sẽ gọi API lại
    final currentState = state;
    if (currentState is CategoryLoaded && 
        currentState.categories.isNotEmpty &&
        currentState.type == event.type) {
      // Đã có data hợp lệ và cùng type, không cần gọi API lại
      return;
    }

    emit(CategoryLoading());

    final result = await categoryRepository.getCategories(event.type);

    result.when(
      success: (data) {
        emit(CategoryLoaded(data ?? [], type: event.type));
      },
      failure: (error) {
        emit(CategoryFailure(error));
      },
    );
  }

  Future<void> _onLoadCategoryImagesSubmitted(
    LoadCategoryImagesSubmitted event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryImagesLoading());

    final result = await categoryRepository.getCategoryImages(
      folder: event.folder,
      limit: event.limit,
      cursor: event.cursor,
    );

    result.when(
      success: (data) {
        emit(CategoryImagesLoaded(data ?? []));
      },
      failure: (error) {
        emit(CategoryImagesFailure(error));
      },
    );
  }

  void _onResetCategories(
    ResetCategories event,
    Emitter<CategoryState> emit,
  ) {
    emit(CategoryInitial());
  }

  Future<void> _onCreateCategorySubmitted(
    CreateCategorySubmitted event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryCreating());

    final result = await categoryRepository.createCategory(
      name: event.name,
      type: event.type,
      image: event.image,
    );

    result.when(
      success: (data) {
        if (data != null) {
          emit(CategoryCreated(data));
        } else {
          emit(CategoryCreateFailure('Không thể tạo danh mục'));
        }
      },
      failure: (error) {
        emit(CategoryCreateFailure(error));
      },
    );
  }
}

