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
    this.maxOptionsHeight = 240,
    this.showPoweredByGoogle = true,
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
  final bool showPoweredByGoogle;


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
                elevation: 6,
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: constraints.maxWidth,
                  constraints: BoxConstraints(maxHeight: widget.maxOptionsHeight),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.grey.shade200,
                          ),
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
                                color: isSelected
                                    ? Colors.grey.shade100
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: widget.style?.copyWith(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ) ??
                                            const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (widget.showPoweredByGoogle) ...[
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade200,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: const Color(0xFFF9F9F9),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "powered by ",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "G",
                                      style: TextStyle(color: Color(0xFF4285F4)),
                                    ),
                                    TextSpan(
                                      text: "o",
                                      style: TextStyle(color: Color(0xFFEA4335)),
                                    ),
                                    TextSpan(
                                      text: "o",
                                      style: TextStyle(color: Color(0xFFFBBC05)),
                                    ),
                                    TextSpan(
                                      text: "g",
                                      style: TextStyle(color: Color(0xFF4285F4)),
                                    ),
                                    TextSpan(
                                      text: "l",
                                      style: TextStyle(color: Color(0xFF34A853)),
                                    ),
                                    TextSpan(
                                      text: "e",
                                      style: TextStyle(color: Color(0xFFEA4335)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
