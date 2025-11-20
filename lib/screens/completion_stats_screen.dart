import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/screens/creation_stats_screen.dart';
import 'package:potential_aid_app/widgets/stats/stat_list.dart';

class CompletionStatsScreen extends ConsumerWidget {
  const CompletionStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Completion Stats'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.account_tree_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreationStatsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StatList(),
    );
  }
}
