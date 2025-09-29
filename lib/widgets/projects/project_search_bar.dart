import 'package:flutter/material.dart';

class ProjectSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const ProjectSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Search projects...'
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(fontSize: 18),
      onChanged: onChanged,
    );
  }
}
