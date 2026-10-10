part of 'category_bloc.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

/// Base class for any state that carries the list.
/// The view only needs to check `state is CategoryWithItems`.
abstract class CategoryWithItems extends CategoryState {
  final List<Category> items;
  const CategoryWithItems(this.items);

  @override
  List<Object?> get props => [items];
}

final class CategoryLoaded extends CategoryWithItems {
  final Category? selected;

  const CategoryLoaded(super.items, {this.selected});

  @override
  List<Object?> get props => [items, selected];
}

final class CategorySaving extends CategoryWithItems {
  const CategorySaving(super.items);
}

final class CategoryActionSuccess extends CategoryWithItems {
  final String message;

  const CategoryActionSuccess(super.items, this.message);

  @override
  List<Object?> get props => [items, message];
}

final class CategoryFailure extends CategoryState {
  final String message;
  const CategoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}