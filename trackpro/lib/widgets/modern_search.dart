// File: lib/widgets/modern_search.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/app_theme.dart';

class ModernSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;
  final bool showClearButton;
  final Duration debounceTime;
  final List<String>? suggestions;
  final bool showSuggestions;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ModernSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onTap,
    this.controller,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.showClearButton = true,
    this.debounceTime = const Duration(milliseconds: 300),
    this.suggestions,
    this.showSuggestions = false,
    this.borderRadius = 12,
    this.margin,
    this.padding,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;

  Timer? _debounceTimer;
  bool _hasFocus = false;
  String _currentText = '';
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _currentText = _controller.text;

    _animationController = AnimationController(
      duration: AppDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.easeInOutQuart,
    ));

    _borderColorAnimation = ColorTween(
      begin: AppTheme.borderColor,
      end: AppTheme.primaryColor,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
    _filterSuggestions(_currentText);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });

    if (_hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleTextChange() {
    final text = _controller.text;
    if (text != _currentText) {
      setState(() {
        _currentText = text;
      });

      _filterSuggestions(text);

      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.debounceTime, () {
        widget.onChanged?.call(text);
      });
    }
  }

  void _filterSuggestions(String query) {
    if (widget.suggestions == null || !widget.showSuggestions) {
      _filteredSuggestions = [];
      return;
    }

    if (query.isEmpty) {
      _filteredSuggestions = widget.suggestions!.take(5).toList();
    } else {
      _filteredSuggestions = widget.suggestions!
          .where((suggestion) =>
              suggestion.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
    }
    setState(() {});
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    HapticFeedback.lightImpact();
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _focusNode.unfocus();
    widget.onChanged?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: widget.margin,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: _borderColorAnimation.value ?? AppTheme.borderColor,
                      width: _hasFocus ? 2 : 1,
                    ),
                    boxShadow: _hasFocus
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (widget.leading != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: widget.leading,
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppTheme.textTertiary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          onTap: widget.onTap,
                          style: AppTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: widget.padding ??
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (widget.showClearButton && _currentText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearText,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.textTertiary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textTertiary,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (widget.trailing != null) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: widget.trailing,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.showSuggestions &&
            _filteredSuggestions.isNotEmpty &&
            _hasFocus)
          _buildSuggestions(),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _filteredSuggestions.map((suggestion) {
          return InkWell(
            onTap: () => _selectSuggestion(suggestion),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppTheme.textTertiary,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                  const Icon(
                    Icons.north_west_rounded,
                    color: AppTheme.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ModernFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;
  final Color? selectedColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const ModernFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.avatar,
    this.selectedColor,
    this.backgroundColor,
    this.padding,
    this.borderRadius = 20,
  });

  @override
  State<ModernFilterChip> createState() => _ModernFilterChipState();
}

class _ModernFilterChipState extends State<ModernFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.easeInOutQuart,
    ));

    _colorAnimation = ColorTween(
      begin: widget.backgroundColor ?? AppTheme.backgroundColor,
      end: widget.selectedColor ?? AppTheme.primaryColor,
    ).animate(_animationController);

    if (widget.selected) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModernFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleTap() {
    if (widget.onSelected != null) {
      widget.onSelected!(!widget.selected);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget.selected
                    ? null
                    : Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.avatar != null) ...[
                    widget.avatar!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppTheme.labelMedium.copyWith(
                      color: widget.selected
                          ? Colors.white
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (widget.selected) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}