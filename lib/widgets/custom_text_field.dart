import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final bool readOnly;
  final Function()? onTap;
  final String? initialValue;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final EdgeInsetsGeometry? contentPadding;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool showCounter;
  final int? minLines;
  final bool? enabledBorder;
  final bool? filled;
  final Color? fillColor;
  final double? borderRadius;
  final Color? borderColor;
  final double? borderWidth;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.onTap,
    this.initialValue,
    this.expands = false,
    this.textAlignVertical,
    this.contentPadding,
    this.decoration,
    this.style,
    this.showCounter = false,
    this.minLines,
    this.enabledBorder = true,
    this.filled = true,
    this.fillColor = Colors.white,
    this.borderRadius = 8.0,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius!), 
      borderSide: BorderSide(
        color: borderColor ?? theme.dividerColor,
        width: borderWidth!,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 4),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          enabled: enabled,
          autofocus: autofocus,
          focusNode: focusNode,
          textAlign: textAlign,
          readOnly: readOnly,
          onTap: onTap,
          expands: expands,
          textAlignVertical: textAlignVertical,
          style: style ?? theme.textTheme.bodyLarge,
          minLines: minLines,
          decoration: decoration ??
              InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                filled: filled,
                fillColor: fillColor,
                contentPadding: contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: defaultBorder,
                enabledBorder: enabledBorder! ? defaultBorder : InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                  borderSide: BorderSide(
                    color: theme.primaryColor,
                    width: borderWidth! * 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: borderWidth!,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: borderWidth! * 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                  borderSide: BorderSide(
                    color: theme.disabledColor,
                    width: borderWidth!,
                  ),
                ),
                suffixIcon: suffixIcon,
                prefixIcon: prefixIcon,
                counterText: showCounter ? null : '',
                errorStyle: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
        ),
      ],
    );
  }
}
