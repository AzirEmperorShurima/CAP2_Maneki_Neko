part of 'category_bloc.dart';

sealed class CategoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCategoriesSubmitted extends CategoryEvent {
  final String? type;

  LoadCategoriesSubmitted({this.type});

  @override
  List<Object?> get props => [type];
}

class LoadCategoryImagesSubmitted extends CategoryEvent {
  final String? folder;
  final int? limit;
  final String? cursor;

  LoadCategoryImagesSubmitted({
    this.folder,
    this.limit,
    this.cursor,
  });

  @override
  List<Object?> get props => [folder, limit, cursor];
}

class ResetCategories extends CategoryEvent {
  ResetCategories();

  @override
  List<Object?> get props => [];
}

class CreateCategorySubmitted extends CategoryEvent {
  final String? name;
  final String? type;
  final String? image;

  CreateCategorySubmitted({
    this.name,
    this.type,
    this.image,
  });

  @override
  List<Object?> get props => [name, type, image];
}

