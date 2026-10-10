import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/medicine_bloc.dart';
import 'model/medicine_model.dart';

typedef MedicineSelected = void Function(Medicine? medicine);

class MedicineSearchField extends StatefulWidget {
  final Medicine? initial;
  final MedicineSelected onSelected;
  final String? label;
  final String hintText;
  final bool enabled;
  final double? width;
  final bool Function(Medicine m)? filter;

  /// Optional external focus node. When provided, the widget uses it instead
  /// of creating its own — lets the parent build a focus chain.
  final FocusNode? focusNode;

  /// After a selection is made, move focus here. Set to the row's Qty node.
  final FocusNode? nextFocusNode;

  const MedicineSearchField({
    super.key,
    this.initial,
    required this.onSelected,
    this.label,
    this.hintText = 'Search medicine…',
    this.enabled = true,
    this.width,
    this.filter,
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  State<MedicineSearchField> createState() => _MedicineSearchFieldState();
}

class _MedicineSearchFieldState extends State<MedicineSearchField> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  late final FocusNode _focusNode;
  late final bool _ownsFocus;

  OverlayEntry? _overlay;
  Timer? _debounce;

  List<Medicine> _items = [];
  int _highlighted = -1;
  bool _loading = false;
  String _query = '';

  Medicine? _selected;

  @override
  void initState() {
    super.initState();

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocus = false;
    } else {
      _focusNode = FocusNode(debugLabel: 'MedicineSearchField');
      _ownsFocus = true;
    }

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
    if (_ownsFocus) _focusNode.dispose();
    _controller.dispose();
    _scrollCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (_controller.text.isNotEmpty || _items.isNotEmpty) {
        _showOverlay();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

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

    if (value.trim().isEmpty) {
      setState(() {
        _items = [];
        _loading = false;
      });
      _removeOverlay();
      return;
    }

    _showOverlay();
    setState(() => _loading = true);

    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context
          .read<MedicineBloc>()
          .add(MedicineLoadRequested(search: value.trim()));
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

  void _select(Medicine m, {bool moveNext = false}) {
    setState(() {
      _selected = m;
      _controller.text = m.medName;
    });
    widget.onSelected(m);
    _removeOverlay();

    if (moveNext && widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
    } else {
      _focusNode.unfocus();
    }
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
      if (_items.isEmpty && _selected != null) {
        if (widget.nextFocusNode != null) {
          widget.nextFocusNode!.requestFocus();
        }
        return KeyEventResult.handled;
      }
      if (_highlighted >= 0 && _highlighted < _items.length) {
        _select(_items[_highlighted], moveNext: true);
      } else if (_items.isNotEmpty) {
        _select(_items.first, moveNext: true);
      } else if (_selected != null && widget.nextFocusNode != null) {
        widget.nextFocusNode!.requestFocus();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.tab) {
      _removeOverlay();
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

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
  // Header strip shown at the top of the overlay
  // -----------------------------------------------------------------
  Widget _buildSearchHeader(ColorScheme scheme) {
    final hasQuery = _query.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: scheme.primary),
          const SizedBox(width: 8),

          // Search hint / current query
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: hasQuery
                        ? 'Searching for '
                        : 'Type to search medicines',
                  ),
                  if (hasQuery)
                    TextSpan(
                      text: '"$_query"',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Match count
          if (!_loading && _items.isNotEmpty)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_items.length} match${_items.length == 1 ? '' : 'es'}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),

          // Keyboard hint
          if (!hasQuery) ...[
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '↑ ↓ to navigate · Enter to select · Esc to close',
                style: TextStyle(
                  fontSize: 10.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverlayContent() {
    final scheme = Theme.of(context).colorScheme;
    final screen = MediaQuery.of(context).size;

    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,                       // ← wider overlay
            maxHeight: screen.height * 0.7,
            minHeight: 240,
          ),
          child: Material(
            elevation: 2,                        // ← subtle elevation
            borderRadius: BorderRadius.circular(8),   // ← 8 radius
            color: scheme.surface,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // -------- Search header --------
                _buildSearchHeader(scheme),

                // -------- Body --------
                Expanded(
                  child: _loading
                      ? const Padding(
                    padding: EdgeInsets.all(24),
                    child:
                    Center(child: CircularProgressIndicator()),
                  )
                      : _items.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 40,
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _query.isEmpty
                              ? 'Type to search medicines'
                              : 'No matches for "$_query"',
                          style: TextStyle(
                              color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                      : Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      // ---- Left: list ----
                      Expanded(
                        flex: 1,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final m = _items[i];
                            final isHl = i == _highlighted;

                            return InkWell(
                              onTap: () =>
                                  _select(m, moveNext: true),
                              onHover: (h) {
                                if (h && _highlighted != i) {
                                  setState(
                                          () => _highlighted = i);
                                  _overlay?.markNeedsBuild();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isHl
                                      ? scheme.primary
                                      .withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: scheme
                                          .outlineVariant
                                          .withValues(alpha: 0.4),
                                      width: 0.5,
                                    ),
                                    left: isHl
                                        ? BorderSide(
                                        color:
                                        scheme.primary,
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
                                        color: scheme
                                            .primaryContainer,
                                        borderRadius:
                                        BorderRadius
                                            .circular(8),
                                      ),
                                      alignment:
                                      Alignment.center,
                                      child: Text(
                                        m.medName.isNotEmpty
                                            ? m.medName[0]
                                            .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: scheme
                                              .onPrimaryContainer,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            m.medName,
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                            style: const TextStyle(
                                              fontWeight:
                                              FontWeight
                                                  .w600,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: 2),
                                          Text(
                                            '${m.dosage ?? ""}'
                                                '${m.dosage != null ? " · " : ""}'
                                                '${m.catName}',
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
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
                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                          horizontal: 6,
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: m.availableStock >
                                            0
                                            ? scheme
                                            .secondaryContainer
                                            : scheme
                                            .errorContainer,
                                        borderRadius:
                                        BorderRadius
                                            .circular(20),
                                      ),
                                      child: Text(
                                        '${m.availableStock}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                          FontWeight.w700,
                                          color: m.availableStock >
                                              0
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

                      // ---- Right: details ----
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
                              ? _detailsPanel(
                              _items[_highlighted])
                              : Center(
                            child: Padding(
                              padding:
                              const EdgeInsets.all(24),
                              child: Text(
                                'Hover a medicine to see details',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: scheme
                                      .onSurfaceVariant,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsPanel(Medicine m) {
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
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  m.medName.isNotEmpty ? m.medName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.medName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.catName,
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
          if (m.dosage != null && m.dosage!.isNotEmpty)
            _detailRow(Icons.science_outlined, 'Dosage', m.dosage!),
          _detailRow(Icons.category_outlined, 'Category', m.catName),
          if (m.companyBrand != null && m.companyBrand!.isNotEmpty)
            _detailRow(Icons.business_outlined, 'Brand', m.companyBrand!),
          _detailRow(Icons.scale_outlined, 'Unit', m.unit),
          const SizedBox(height: 12),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: m.availableStock > 0
                  ? scheme.secondaryContainer.withValues(alpha: 0.5)
                  : scheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  m.availableStock > 0
                      ? Icons.medical_information_outlined
                      : Icons.block_outlined,
                  color: m.availableStock > 0
                      ? scheme.onSecondaryContainer
                      : scheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: m.availableStock > 0
                              ? scheme.onSecondaryContainer
                              : scheme.onErrorContainer,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.availableStock > 0
                            ? '${m.availableStock} units'
                            : 'Out of stock',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: m.availableStock > 0
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

  void _onBlocState(MedicineState state) {
    if (!mounted) return;
    if (state is! MedicineWithItems) return;

    List<Medicine> items = state.items;
    if (widget.filter != null) {
      items = items.where(widget.filter!).toList();
    }

    setState(() {
      _items = items;
      _loading = false;
      if (_items.isNotEmpty && _highlighted == -1) {
        _highlighted = 0;
      } else if (_items.isEmpty) {
        _highlighted = -1;
      }
    });

    _overlay?.markNeedsBuild();
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
                    vertical: 12, horizontal: 12),
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.3),
                      width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.3),
                      width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                  BorderSide(color: scheme.primary, width: 1.2),
                ),
              ),
            ),
          ),
          BlocListener<MedicineBloc, MedicineState>(
            listenWhen: (prev, curr) =>
            curr is MedicineWithItems || curr is MedicineLoading,
            listener: (context, state) {
              if (state is MedicineLoading) {
                if (mounted) setState(() => _loading = true);
                _overlay?.markNeedsBuild();
              } else {
                _onBlocState(state);
              }
            },
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}