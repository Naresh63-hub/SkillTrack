import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final Widget? trailing;

  const SearchFilterBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    required this.onChanged,
    this.onClear,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style:
                  const TextStyle(color: AppColors.primaryText, fontSize: 13),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: hintText,
                hintStyle:
                    const TextStyle(color: AppColors.mutedText, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.mutedText, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.mutedText, size: 18),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                          if (onClear != null) onClear!();
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
