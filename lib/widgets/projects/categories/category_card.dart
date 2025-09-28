import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';

class CategoryCard extends StatelessWidget {
  final ProjectCategoryData data;
  const CategoryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: data.title == null || data.title!.isEmpty
          ? _buildIconView(data.iconCodePoint!)
          : (data.iconCodePoint == null
                ? _buildTitleView(data.title!)
                : _buildIconTitleView(data.title!, data.iconCodePoint!)),
    );
  }

  Widget _buildIconView(int iconCodePoint) {
    return Center(
      child: Icon(IconData(iconCodePoint, fontFamily: 'MaterialIcons')),
    );
  }

  Widget _buildTitleView(String title) {
    return Center(child: Text(title));
  }

  Widget _buildIconTitleView(String title, int iconCodePoint) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title),
        Icon(IconData(iconCodePoint, fontFamily: 'MaterialIcons')),
      ],
    );
  }
}
