import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Medicine/batch_bloc/batch_bloc.dart';
import 'model/stock_model.dart';

class BatchPickerField extends StatefulWidget {
  final StockBatchOption? initial;
  final ValueChanged<StockBatchOption?> onSelected;

  /// Optional label above the field.
  final String? label;

  /// Placeholder text.
  final String hintText;

  /// Disable interaction.
  final bool enabled;

  /// Optional custom width.
  final double? width;

  const BatchPickerField({
    super.key,
    this.initial,
    required this.onSelected,
    this.label,
    this.hintText = 'Search batch…',
    this.enabled = true,
    this.width,
  });

  @override
  State<BatchPickerField> createState() => _BatchPickerFieldState();
}

class _BatchPickerFieldState extends State<BatchPickerField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();

  OverlayEntry? _overlay;
  Timer? _debounce;

  List<StockBatchOption> _items = [];
  int _highlighted = -1;
  bool _loading = false;
  String _query = '';

  StockBatchOption? _selected;

  @override
  void initState() {
    super.initState();

    _focusNode.onKeyEvent = _onKey;

    _selected = widget.initial;
    if (_selected != null) {
      _controller.text = _selected!.medName;
    }

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.onKeyEvent = null;
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Focus
  // -----------------------------------------------------------------
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
      // Load once on first focus
      context.read<BatchBloc>().add(const BatchLoadRequested());
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  // -----------------------------------------------------------------
  // Search
  // -----------------------------------------------------------------
  void _onTextChanged(String value) {
    if (_selected != null && value != _selected!.medName) {
      _selected = null;
      widget.onSelected(null);
    }

    setState(() {
      _highlighted = -1;
      _query = value.trim();
    });

    _debounce?.cancel();
    _showOverlay();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<BatchBloc>().add(
        BatchLoadRequested(search: value.trim()),
      );
    });
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _selected = null;
      _items = [];
      _highlighted = -1;
      _query = '';
      _loading = false;
    });
    widget.onSelected(null);
    _removeOverlay();
    _focusNode.requestFocus();
  }

  // -----------------------------------------------------------------
  // Selection
  // -----------------------------------------------------------------
  void _select(StockBatchOption b) {
    setState(() {
      _selected = b;
      _controller.text = b.medName;
    });
    widget.onSelected(b);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _highlight(int index) {
    if (_items.isEmpty) return;
    setState(() {
      _highlighted = index.clamp(0, _items.length - 1);
    });
    _scrollToHighlighted();
    _overlay?.markNeedsBuild();
  }

  void _scrollToHighlighted() {
    if (!_scrollCtrl.hasClients || _highlighted < 0) return;
    const itemHeight = 64.0;
    final target = _highlighted * itemHeight;
    final viewport = _scrollCtrl.position.viewportDimension;

    if (target < _scrollCtrl.offset) {
      _scrollCtrl.animateTo(target,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut);
    } else if (target + itemHeight > _scrollCtrl.offset + viewport) {
      _scrollCtrl.animateTo(target + itemHeight - viewport,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut);
    }
  }

  // -----------------------------------------------------------------
  // Keyboard
  // -----------------------------------------------------------------
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      _removeOverlay();
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_items.isEmpty) return KeyEventResult.handled;
      _highlight(_highlighted + 1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (_items.isEmpty) return KeyEventResult.handled;
      _highlight(_highlighted - 1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.home) {
      if (_items.isNotEmpty) _highlight(0);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.end) {
      if (_items.isNotEmpty) _highlight(_items.length - 1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_highlighted >= 0 && _highlighted < _items.length) {
        _select(_items[_highlighted]);
      } else if (_items.isNotEmpty) {
        _select(_items.first);
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.tab) {
      _removeOverlay();
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  // -----------------------------------------------------------------
  // Overlay
  // -----------------------------------------------------------------
  void _showOverlay() {
    if (_overlay != null) {
      _overlay!.markNeedsBuild();
      return;
    }
    _overlay = OverlayEntry(builder: (_) => _buildOverlayContent());
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  // -----------------------------------------------------------------
  // Bloc state updates
  // -----------------------------------------------------------------
  void _onBlocState(BatchState state) {
    if (!mounted) return;

    if (state is BatchLoading) {
      setState(() => _loading = true);
      _overlay?.markNeedsBuild();
      return;
    }

    if (state is BatchFailure) {
      setState(() {
        _items = [];
        _loading = false;
        _highlighted = -1;
      });
      _overlay?.markNeedsBuild();
      return;
    }

    if (state is BatchLoaded) {
      final lowered = _query.toLowerCase();
      final filtered = _query.isEmpty
          ? state.items
          : state.items
          .where((b) =>
      b.medName.toLowerCase().contains(lowered) ||
          b.batchNo.toLowerCase().contains(lowered))
          .toList();

      setState(() {
        _items = filtered;
        _loading = false;
        if (_items.isNotEmpty && _highlighted == -1) {
          _highlighted = 0;
        } else if (_items.isEmpty) {
          _highlighted = -1;
        }
      });
      _overlay?.markNeedsBuild();
    }
  }

  Widget _buildOverlayContent() {
    final scheme = Theme.of(context).colorScheme;
    final screen = MediaQuery.of(context).size;

    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: screen.height * 0.7,
            minHeight: 240,
          ),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: scheme.surface,
            clipBehavior: Clip.antiAlias,
            child: _loading
                ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
                : _items.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 40,
                      color: scheme.onSurfaceVariant
                          .withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    _query.isEmpty
                        ? 'No active batches'
                        : 'No matches for "$_query"',
                    style: TextStyle(
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final b = _items[i];
                      final isHl = i == _highlighted;

                      return InkWell(
                        onTap: () => _select(b),
                        onHover: (h) {
                          if (h && _highlighted != i) {
                            setState(() => _highlighted = i);
                            _overlay?.markNeedsBuild();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isHl
                                ? scheme.primary
                                .withValues(alpha: 0.08)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                              left: isHl
                                  ? BorderSide(
                                  color: scheme.primary,
                                  width: 3)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color:
                                  scheme.tertiaryContainer,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: scheme
                                      .onTertiaryContainer,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.medName,
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Batch ${b.batchNo}  ·  exp ${b.expiryDate}',
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: scheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: b.quantityRemaining > 0
                                      ? scheme.secondaryContainer
                                      : scheme.errorContainer,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${b.quantityRemaining}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color:
                                    b.quantityRemaining > 0
                                        ? scheme
                                        .onSecondaryContainer
                                        : scheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      border: Border(
                        left: BorderSide(
                          color: scheme.outlineVariant
                              .withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _highlighted >= 0 &&
                        _highlighted < _items.length
                        ? _detailsPanel(_items[_highlighted])
                        : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Hover a batch to see details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsPanel(StockBatchOption b) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 22,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.medName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Batch ${b.batchNo}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(Icons.tag_outlined, 'Batch no', b.batchNo),
          _detailRow(Icons.event_busy_outlined, 'Expiry', b.expiryDate),
          if (b.dosage != null && b.dosage!.isNotEmpty)
            _detailRow(Icons.science_outlined, 'Dosage', b.dosage!),
          if (b.unit != null && b.unit!.isNotEmpty)
            _detailRow(Icons.scale_outlined, 'Unit', b.unit!),
          const SizedBox(height: 12),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: b.quantityRemaining > 0
                  ? scheme.secondaryContainer.withValues(alpha: 0.5)
                  : scheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  b.quantityRemaining > 0
                      ? Icons.inventory_2_outlined
                      : Icons.block_outlined,
                  color: b.quantityRemaining > 0
                      ? scheme.onSecondaryContainer
                      : scheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Quantity',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: b.quantityRemaining > 0
                              ? scheme.onSecondaryContainer
                              : scheme.onErrorContainer,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.quantityRemaining > 0
                            ? '${b.quantityRemaining} units'
                            : 'Empty',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: b.quantityRemaining > 0
                              ? scheme.onSecondaryContainer
                              : scheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null && widget.label!.isNotEmpty) ...[
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: 4),
          ],
          SizedBox(
            width: widget.width,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              onChanged: _onTextChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clear,
                  tooltip: 'Clear',
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.5),
                      width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.5),
                      width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                  BorderSide(color: scheme.primary, width: 1.2),
                ),
              ),
            ),
          ),
          // Silently listen to the BatchBloc for state updates
          BlocListener<BatchBloc, BatchState>(
            listenWhen: (prev, curr) =>
            curr is BatchLoaded ||
                curr is BatchLoading ||
                curr is BatchFailure,
            listener: (context, state) => _onBlocState(state),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}