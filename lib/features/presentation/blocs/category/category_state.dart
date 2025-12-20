part of 'category_bloc.dart';

abstract class CategoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  final String? type;

  CategoryLoaded(this.categories, {this.type});

  @override
  List<Object?> get props => [categories, type];
}

class CategoryFailure extends CategoryState {
  final String message;

  CategoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class CategoryImagesLoading extends CategoryState {}

class CategoryImagesLoaded extends CategoryState {
  final List<CategoryImageModel> images;

  CategoryImagesLoaded(this.images);

  @override
  List<Object?> get props => [images];
}

class CategoryImagesFailure extends CategoryState {
  final String message;

  CategoryImagesFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class CategoryCreating extends CategoryState {}

class CategoryCreated extends CategoryState {
  final CategoryModel category;

  CategoryCreated(this.category);

  @override
  List<Object?> get props => [category];
}

class CategoryCreateFailure extends CategoryState {
  final String message;

  CategoryCreateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

