import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class TextFieldFormBuilder extends StatefulWidget {
  const TextFieldFormBuilder({
    super.key,
    required this.name,
    this.hintText,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.isEdit = true,
    this.isNumeric = false,
    this.digitsOnly = false,
    this.borderRadius,
    this.textAlign = TextAlign.start,
    this.allowZero = false,
    this.resetTextAfterSubmit = false,
    this.negativeNumbers = false,
    this.keyboardType,
    this.icon,
    this.suffixWidget,
    this.enabled = true,
    this.isDisable = false,
  });

  final String name;
  final String? hintText;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  final bool isEdit;
  final bool isNumeric;
  final bool digitsOnly;
  final bool allowZero;
  final bool resetTextAfterSubmit;
  final bool negativeNumbers;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final double? borderRadius;
  final IconData? icon;
  final Widget? suffixWidget;
  final bool enabled;
  final bool isDisable;

  @override
  State<TextFieldFormBuilder> createState() => _TextFieldFormBuilderState();
}

class _TextFieldFormBuilderState extends State<TextFieldFormBuilder> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && widget.onSubmitted != null) {
        widget.onSubmitted!(_controller.text);
        if (widget.resetTextAfterSubmit) _controller.clear();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialValue != null && _controller.text != widget.initialValue) {
      final cursorPosition = _controller.selection.baseOffset;
      _controller.value = _controller.value.copyWith(
        text: widget.initialValue!,
        selection: TextSelection.collapsed(
          offset: cursorPosition.clamp(0, widget.initialValue!.length),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.borderRadius ?? 4);

    return FormBuilderField<String>(
      name: widget.name,
      validator: widget.validator,
      initialValue: widget.initialValue,
      autovalidateMode: AutovalidateMode.disabled,
      builder: (field) {
        // sync controller value
        if (_controller.text != field.value) {
          _controller.text = field.value ?? '';
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField( 
              controller: _controller,
              focusNode: widget.isEdit ? _focusNode : null,
              readOnly: !widget.isEdit,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType ??
                  (widget.isNumeric ? TextInputType.number : TextInputType.text),
              // inputFormatters: _buildInputFormatters(),
              textAlign: widget.textAlign,
              style: TextStyle(
                color: widget.isDisable ? Colors.grey : Colors.black,
              ),
              onTapOutside: (event) {
                _focusNode.unfocus();
                if (widget.isEdit && widget.onSubmitted != null) {
                  widget.onSubmitted!(_controller.text);
                }
                if (widget.resetTextAfterSubmit) {
                  _controller.clear();
                }
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: widget.isDisable 
                    ? Colors.grey.shade50 
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(
                    color: field.hasError
                        ? Colors.red
                        : Colors.black.withOpacity(.3),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(
                    color: field.hasError
                        ? Colors.red
                        : Colors.black.withOpacity(.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(
                    color: field.hasError
                        ? Colors.red
                        : Colors.blue,
                    width: 1,
                  ),
                ),
                prefixIcon: widget.icon != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                suffixIcon: widget.suffixWidget,
              ),
              onChanged: (value) {
                final oldOffset = _controller.selection.baseOffset;

                if (!widget.allowZero && value.startsWith('0')) {
                  _controller.text = value.substring(1);
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                  return;
                }

                if ((widget.isNumeric ||
                        widget.keyboardType == TextInputType.number ||
                        widget.keyboardType ==
                            const TextInputType.numberWithOptions(decimal: true)) &&
                    !widget.negativeNumbers) {
                  var newValue = value.replaceAll(RegExp(r'[^0-9.]'), '');

                  if (newValue.startsWith('0') &&
                      newValue.length > 1 &&
                      !newValue.contains('.')) {
                    newValue = newValue.substring(1);
                  }

                  if (newValue.contains('.')) {
                    final parts = newValue.split('.');
                    if (parts.length > 2) {
                      newValue = '${parts[0]}.${parts.sublist(1).join()}';
                    }
                  }

                  if (newValue != value) {
                    _controller.text = newValue;
                    final newOffset = oldOffset.clamp(0, newValue.length);
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: newOffset),
                    );
                  }
                }

                field.didChange(_controller.text);
                widget.onChanged?.call(_controller.text);

                if(field.hasError && _controller.text.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    field.validate();
                  });
                }
              },

              onSubmitted: widget.onSubmitted,
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<TextInputFormatter> _buildInputFormatters() {
    if (!widget.isNumeric) return [];

    return [
      TextInputFormatter.withFunction((oldValue, newValue) {
        String value = newValue.text;
        int baseOffset = newValue.selection.baseOffset;

        // ลบ 0 นำหน้า ถ้าไม่อนุญาตให้มี 0 นำหน้า
        if (!widget.allowZero && value.startsWith('0') && value.length > 1 && !value.contains('.')) {
          value = value.replaceFirst(RegExp(r'^0+'), '');
          baseOffset = baseOffset - 1;
        }

        // ตัวเลขเท่านั้น (และ . ได้ ถ้าไม่ห้าม)
        if ((widget.isNumeric ||
                widget.keyboardType == TextInputType.number ||
                widget.keyboardType == TextInputType.numberWithOptions(decimal: true)) &&
            !widget.negativeNumbers) {
          value = value.replaceAll(RegExp(r'[^0-9.]'), '');

          // ป้องกันการมี . มากกว่า 1 จุด
          if (value.contains('.')) {
            final parts = value.split('.');
            if (parts.length > 2) {
              value = '${parts[0]}.${parts.sublist(1).join()}';
              baseOffset = value.length;
            }
          }
        }

        return TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: baseOffset.clamp(0, value.length)),
        );
      }),
    ];
  }
}





