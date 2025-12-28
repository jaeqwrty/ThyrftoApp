import 'package:flutter/material.dart';
/// Custom choice chips for category/condition selection

class CustomChoiceChips extends StatelessWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const CustomChoiceChips({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return ChoiceChip(
          label: Text(
            option,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onSelected(option);
          },
          selectedColor: const Color(0xFF8B5CF6),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isSelected
                ? BorderSide.none
                : BorderSide(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          elevation: isSelected ? 2 : 0,
        );
      }).toList(),
    );
  }
}