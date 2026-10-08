part of 'category_bloc.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

/// Load the full list
final class CategoryLoadRequested extends CategoryEvent {
  const CategoryLoadRequested();
}

/// Load one category (with medicine count)
final class CategorySelectRequested extends CategoryEvent {
  final int catId;
  const CategorySelectRequested(this.catId);

  @override
  List<Object?> get props => [catId];
}

/// Clear the current selection
final class CategoryClearSelection extends CategoryEvent {
  const CategoryClearSelection();
}

/// Create
final class CategoryCreateRequested extends CategoryEvent {
  final CategoryRequest request;
  const CategoryCreateRequested(this.request);

  @override
  List<Object?> get props => [request];
}

/// Update
final class CategoryUpdateRequested extends CategoryEvent {
  final int catId;
  final CategoryRequest request;
  const CategoryUpdateRequested(this.catId, this.request);

  @override
  List<Object?> get props => [catId, request];
}

/// Delete
final class CategoryDeleteRequested extends CategoryEvent {
  final int catId;
  const CategoryDeleteRequested(this.catId);

  @override
  List<Object?> get props => [catId];
}