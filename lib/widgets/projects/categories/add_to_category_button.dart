import 'package:flutter/material.dart';
import 'package:potential_aid_app/widgets/projects/categories/add_to_category_dialog.dart';

class AddToCategory extends StatelessWidget {
  final int projectId;
  const AddToCategory({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: () => showAddToCategoryDialog(context, projectId), icon: Icon(Icons.category_rounded));
  }
}