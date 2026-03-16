import 'package:flutter/material.dart';
import 'package:potential_aid_app/schedule/widgets/add_block_dialog.dart';

class AddBlockDialogButton extends StatelessWidget {
  const AddBlockDialogButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showAddBlockDialog(context);
      },
      icon: const Icon(Icons.add),
      label: const Text('Block'),
    );
  }
}
