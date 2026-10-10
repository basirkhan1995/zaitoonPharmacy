import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../../Services/api_exception.dart';
import '../../../../../../../Services/repository.dart';
import '../model/med_category_model.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final Repositories _repo;

  CategoryBloc(this._repo) : super(const CategoryInitial()) {
    on<CategoryLoadRequested>(_onLoad);
    on<CategorySelectRequested>(_onSelect);
    on<CategoryClearSelection>(_onClear);
    on<CategoryCreateRequested>(_onCreate);
    on<CategoryUpdateRequested>(_onUpdate);
    on<CategoryDeleteRequested>(_onDelete);
  }

  List<Category> get _currentItems =>
      state is CategoryWithItems
          ? (state as CategoryWithItems).items
          : const [];

  Future<void> _onLoad(
      CategoryLoadRequested event, Emitter<CategoryState> emit) async {
    emit(const CategoryLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500));
      final items = await _repo.getCategories();
      emit(CategoryLoaded(items));
    } on ApiException catch (e) {
      emit(CategoryFailure(e.message));
    }
  }

  Future<void> _onSelect(
      CategorySelectRequested event, Emitter<CategoryState> emit) async {
    final items = _currentItems;
    emit(const CategoryLoading());
    try {
      final category = await _repo.getCategory(event.catId);
      emit(CategoryLoaded(items, selected: category));
    } on ApiException catch (e) {
      emit(CategoryFailure(e.message));
    }
  }

  Future<void> _onClear(
      CategoryClearSelection event, Emitter<CategoryState> emit) async {
    emit(CategoryLoaded(_currentItems));
  }

  Future<void> _onCreate(
      CategoryCreateRequested event, Emitter<CategoryState> emit) async {
    emit(CategorySaving(_currentItems));
    try {
      await _repo.createCategory(event.request);
      final items = await _repo.getCategories();
      // Single emit — carries items AND the toast message
      emit(CategoryActionSuccess(items, 'Category created'));
    } on ApiException catch (e) {
      emit(CategoryFailure(e.message));
    }
  }

  Future<void> _onUpdate(
      CategoryUpdateRequested event, Emitter<CategoryState> emit) async {
    emit(CategorySaving(_currentItems));
    try {
      await _repo.updateCategory(event.catId, event.request);
      final items = await _repo.getCategories();
      emit(CategoryActionSuccess(items, 'Category updated'));
    } on ApiException catch (e) {
      emit(CategoryFailure(e.message));
    }
  }

  Future<void> _onDelete(
      CategoryDeleteRequested event, Emitter<CategoryState> emit) async {
    emit(CategorySaving(_currentItems));
    try {
      await _repo.deleteCategory(event.catId);
      final items = await _repo.getCategories();
      emit(CategoryActionSuccess(items, 'Category deleted'));
    } on ApiException catch (e) {
      emit(CategoryFailure(e.message));
    }
  }
}