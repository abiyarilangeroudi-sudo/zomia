import 'package:flutter/material.dart';

import '../../../app/brand/brand_colors.dart';

class TermsAcceptanceRow extends StatelessWidget {
  const TermsAcceptanceRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.prefix,
    required this.termsLabel,
    required this.privacyLabel,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String prefix;
  final String termsLabel;
  final String privacyLabel;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final linkStyle = textStyle?.copyWith(
      color: BrandColors.orange,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: BrandColors.orange,
          checkColor: BrandColors.surface,
          side: const BorderSide(color: BrandColors.textSecondary, width: 1.6),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('$prefix ', style: textStyle),
              _TermsLink(
                label: termsLabel,
                style: linkStyle,
                onTap: onTermsTap,
              ),
              Text(' & ', style: textStyle),
              _TermsLink(
                label: privacyLabel,
                style: linkStyle,
                onTap: onPrivacyTap,
              ),
              Text('.', style: textStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _TermsLink extends StatelessWidget {
  const _TermsLink({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        child: Text(label, style: style),
      ),
    );
  }
}
