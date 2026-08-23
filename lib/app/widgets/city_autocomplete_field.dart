import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// City/location autocomplete that closes suggestions and dismisses keyboard on select.
class CityAutocompleteField extends StatefulWidget {
  const CityAutocompleteField({
    super.key,
    required this.controller,
    required this.optionsBuilder,
    required this.decoration,
    this.style,
    this.onChanged,
    this.onSelected,
    this.isDense = false,
    this.label,
    this.labelSpacing = 5,
    this.maxOptionsHeight = 220,
  });

  final TextEditingController controller;
  final FutureOr<Iterable<String>> Function(TextEditingValue) optionsBuilder;
  final InputDecoration decoration;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSelected;
  final bool isDense;
  final Widget? label;
  final double labelSpacing;
  final double maxOptionsHeight;

  static void dismissSuggestions(BuildContext context) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  bool _hideSuggestions = false;
  int _activeIndex = -1;

  void _closeDropdown(BuildContext context) {
    setState(() {
      _hideSuggestions = true;
      _activeIndex = -1;
    });
    CityAutocompleteField.dismissSuggestions(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CityAutocompleteField.dismissSuggestions(context);
    });
  }

  void _handleSelection(BuildContext context, String selection) {
    widget.controller.text = selection;
    widget.onSelected?.call(selection);
    widget.onChanged?.call(selection);
    _closeDropdown(context);
  }

  FutureOr<Iterable<String>> _buildOptions(TextEditingValue value) {
    if (_hideSuggestions) return const Iterable<String>.empty();
    return widget.optionsBuilder(value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<String>(
          displayStringForOption: (option) => option,
          optionsBuilder: _buildOptions,
          onSelected: (selection) => _handleSelection(context, selection),
          fieldViewBuilder: (
            context,
            textEditingController,
            focusNode,
            onFieldSubmittedCallback,
          ) {
            if (textEditingController.text != widget.controller.text) {
              textEditingController.text = widget.controller.text;
              textEditingController.selection = TextSelection.collapsed(
                offset: widget.controller.text.length,
              );
            }

            focusNode.addListener(() {
              if (!focusNode.hasFocus && mounted) {
                setState(() => _hideSuggestions = true);
              }
            });

            final field = TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              style: widget.style ?? const TextStyle(fontSize: 14, color: Colors.black87),
              onChanged: (value) {
                if (_hideSuggestions) {
                  setState(() => _hideSuggestions = false);
                }
                widget.controller.text = value;
                widget.onChanged?.call(value);
              },
              onTapOutside: (_) => _closeDropdown(context),
              onFieldSubmitted: (_) {
                _closeDropdown(context);
                onFieldSubmittedCallback();
              },
              decoration: widget.decoration,
            );

            if (widget.label == null) return field;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.label!,
                SizedBox(height: widget.labelSpacing),
                field,
              ],
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            if (_hideSuggestions || options.isEmpty) {
              return const SizedBox.shrink();
            }

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: BoxConstraints(maxHeight: widget.maxOptionsHeight),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final isSelected = _activeIndex == index;
                      return InkWell(
                        onTap: () => _handleSelection(context, option),
                        onHover: (hovering) {
                          if (hovering) {
                            setState(() => _activeIndex = index);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            option,
                            style: widget.style?.copyWith(fontSize: 14) ?? const TextStyle(fontSize: 14, color: Colors.black87),
                            softWrap: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }
}
