import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/widgets/categories/category_icon_picker_sheet.dart';

class CategoryCard extends StatelessWidget {
  final ProjectCategoryData data;
  const CategoryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillHeight = constraints.maxHeight.isFinite;

          Widget content;
          if (data.title == null || data.title!.isEmpty) {
            content = _buildIconView(context, data.iconCodePoint!);
          } else if (data.iconCodePoint == null) {
            content = _buildTitleView(context, data.title!);
          } else {
            content = _buildIconTitleView(
              context,
              data.title!,
              data.iconCodePoint!,
            );
          }

          if (fillHeight) {
            return SizedBox(
              width: constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : double.infinity,
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(child: content),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildIconView(BuildContext context, int iconCodePoint) {
    return Icon(
      iconDataFromCodePoint(iconCodePoint),
      size: 40,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildTitleView(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildIconTitleView(
    BuildContext context,
    String title,
    int iconCodePoint,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Icon(
          iconDataFromCodePoint(iconCodePoint),
          size: 36,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}
