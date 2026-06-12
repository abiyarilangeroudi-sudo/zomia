import 'package:flutter/material.dart';

class ZomiaTextField extends StatefulWidget {
  const ZomiaTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final bool enabled;

  @override
  State<ZomiaTextField> createState() => _ZomiaTextFieldState();
}

class _ZomiaTextFieldState extends State<ZomiaTextField> {
  late bool _isObscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final hasVisibilityToggle = widget.obscureText && widget.suffixIcon == null;
    final field = TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _isObscured,
      maxLines: widget.maxLines,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: hasVisibilityToggle
            ? IconButton(
                tooltip: _isObscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _isObscured = !_isObscured),
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : widget.suffixIcon,
      ),
    );
    if (widget.maxLines > 1) {
      return field;
    }
    return SizedBox(height: 52, child: field);
  }
}
