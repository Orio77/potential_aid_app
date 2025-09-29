import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';

class CategoryCard extends StatelessWidget {
  final ProjectCategoryData data;
  const CategoryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        child: data.title == null || data.title!.isEmpty
            ? _buildIconView(context, data.iconCodePoint!)
            : (data.iconCodePoint == null
                  ? _buildTitleView(context, data.title!)
                  : _buildIconTitleView(
                      context,
                      data.title!,
                      data.iconCodePoint!,
                    )),
      ),
    );
  }

  Widget _buildIconView(BuildContext context, int iconCodePoint) {
    return Center(
      child: Icon(
        IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
        size: 32,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTitleView(BuildContext context, String title) {
    return Center(
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildIconTitleView(
    BuildContext context,
    String title,
    int iconCodePoint,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8.0),
        Icon(
          IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
          size: 28,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}
