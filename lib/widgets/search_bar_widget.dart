import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search pantry items...',
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.white,
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      onChanged: onChanged,
    );
  }
}