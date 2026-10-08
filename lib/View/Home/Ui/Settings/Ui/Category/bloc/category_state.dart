part of 'category_bloc.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// Nothing loaded yet
final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

/// List is loading
final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

/// List loaded (may be empty); optionally one selected
final class CategoryLoaded extends CategoryState {
  final List<Category> items;
  final Category? selected;

  const CategoryLoaded(this.items, {this.selected});

  CategoryLoaded copyWith({
    List<Category>? items,
    Category? selected,
  }) => CategoryLoaded(
    items ?? this.items,
    selected: selected ?? this.selected,
  );

  @override
  List<Object?> get props => [items, selected];
}

/// A create / update / delete is in flight
final class CategorySaving extends CategoryState {
  final List<Category> items;
  const CategorySaving(this.items);

  @override
  List<Object?> get props => [items];
}

/// Operation succeeded — one-shot signal for the UI
final class CategoryActionSuccess extends CategoryState {
  final String message;
  const CategoryActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Something failed
final class CategoryFailure extends CategoryState {
  final String message;
  const CategoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}