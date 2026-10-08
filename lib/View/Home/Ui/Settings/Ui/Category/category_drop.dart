import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../Features/zdropdown.dart';
import 'bloc/category_bloc.dart';
import 'model/med_category_model.dart';   // adjust path to your ZDropdown file

class MedicineCategoryDropView extends StatefulWidget {
  /// Currently selected category (null for none).
  final Category? selected;

  /// Called when the user picks a category.
  final ValueChanged<Category> onSelected;

  final String? title;
  final String? hint;
  final double? radius;
  final double? height;
  final bool enabled;

  const MedicineCategoryDropView({
    super.key,
    this.selected,
    required this.onSelected,
    this.title,
    this.hint,
    this.radius,
    this.height,
    this.enabled = true,
  });

  @override
  State<MedicineCategoryDropView> createState() =>
      _MedicineCategoryDropViewState();
}

class _MedicineCategoryDropViewState extends State<MedicineCategoryDropView> {
  @override
  void initState() {
    super.initState();
    // Load categories once when this widget first appears.
    // If already loaded, the bloc ignores duplicate loads harmlessly,
    // but we can also guard by checking the current state:
    final bloc = context.read<CategoryBloc>();
    if (bloc.state is! CategoryLoaded) {
      bloc.add(const CategoryLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        final items = switch (state) {
          CategoryLoaded() => state.items,
          CategorySaving() => state.items,
          _ => const <Category>[],
        };

        final loading = state is CategoryLoading;
        final hasError = state is CategoryFailure;

        if (hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title != null) ...[
                Text(
                  widget.title!,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontSize: 12,
                      color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 4),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius ?? 4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context
                          .read<CategoryBloc>()
                          .add(const CategoryLoadRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return ZDropdown<Category>(
          title: widget.title,
          items: items,
          selectedItem: widget.selected,
          itemLabel: (c) => c.catName,
          initialValue: widget.hint ?? 'Select category',
          radius: widget.radius,
          height: widget.height,
          isLoading: loading,
          disableAction: !widget.enabled,
          leadingBuilder: (c) => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          onItemSelected: (c) => widget.onSelected(c),
        );
      },
    );
  }
}