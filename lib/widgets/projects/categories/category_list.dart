import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_categories_notifier.dart';
import 'package:potential_aid_app/screens/project_list_screen.dart';
import 'package:potential_aid_app/widgets/projects/categories/category_card.dart';

class CategoryList extends ConsumerWidget {
  const CategoryList({super.key});

  Widget _buildEmptyListView() {
    return Center(child: Text("Create Your First Category to Begin!"));
  }

  Widget _buildCategoryListView(List<ProjectCategoryData> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final category = data[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => _pushProjectListScreen(context, category.id),
                  child: CategoryCard(data: category),
                ),
              );
            },
          );
        }

        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        } else {
          crossAxisCount = 3;
          childAspectRatio = 1.0;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final category = data[index];
            return InkWell(
              onTap: () => _pushProjectListScreen(context, category.id),
              child: CategoryCard(data: category),
            );
          },
        );
      },
    );
  }

  void _pushProjectListScreen(BuildContext context, int? categoryId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectListScreen(categoryId: categoryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(projectCategoriesNotifier);
    return data.isEmpty ? _buildEmptyListView() : _buildCategoryListView(data);
  }
}
