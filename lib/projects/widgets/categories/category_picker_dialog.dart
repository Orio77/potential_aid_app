import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';

Future<ProjectCategoryData?> showProjectCategoryPicker({
  required BuildContext context,
  required List<ProjectCategoryData> categories,
  required String title,
}) {
  if (categories.isEmpty) {
    return Future.value(null);
  }
  return showDialog<ProjectCategoryData>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final c = categories[i];
            final name = (c.title?.trim().isNotEmpty ?? false)
                ? c.title!
                : 'Untitled';
            return ListTile(
              leading: Icon(
                c.iconCodePoint != null
                    ? IconData(c.iconCodePoint!, fontFamily: 'MaterialIcons')
                    : Icons.category_outlined,
              ),
              title: Text(name),
              onTap: () => Navigator.pop(ctx, c),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

String categoryDisplayTitle(ProjectCategoryData c) {
  return (c.title?.trim().isNotEmpty ?? false) ? c.title! : 'Untitled';
}
