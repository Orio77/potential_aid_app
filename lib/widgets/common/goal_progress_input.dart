import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoalProgressInput extends StatefulWidget {
  final TextEditingController currentController;
  final TextEditingController endGoalController;
  final TextEditingController unitController;
  final bool autoFocus;
  final GoalProgressInputController? controller;

  const GoalProgressInput({
    super.key,
    required this.currentController,
    required this.endGoalController,
    required this.unitController,
    this.autoFocus = false,
    this.controller,
  });

  @override
  State<GoalProgressInput> createState() => _GoalProgressInputState();
}

class GoalProgressInputController {
  _GoalProgressInputState? _state;

  void _attach(_GoalProgressInputState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void focusFirst() {
    _state?._focusFirst();
  }

  void focusGoal() {
    _state?._focusGoal();
  }

  void focusUnit() {
    _state?._focusUnit();
  }
}

class _GoalProgressInputState extends State<GoalProgressInput> {
  late FocusNode _currentFocusNode;
  late FocusNode _goalFocusNode;
  late FocusNode _unitFocusNode;

  @override
  void initState() {
    super.initState();

    _currentFocusNode = FocusNode();
    _goalFocusNode = FocusNode();
    _unitFocusNode = FocusNode();

    widget.controller?._attach(this);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();

    _currentFocusNode.dispose();
    _goalFocusNode.dispose();
    _unitFocusNode.dispose();
    super.dispose();
  }

  void _focusNext(FocusNode nextFocus) {
    FocusScope.of(context).requestFocus(nextFocus);
  }

  void _focusFirst() {
    _currentFocusNode.requestFocus();
  }

  void _focusGoal() {
    _goalFocusNode.requestFocus();
  }

  void _focusUnit() {
    _unitFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: widget.currentController,
                  focusNode: _currentFocusNode,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Current',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _focusNext(_goalFocusNode),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: widget.endGoalController,
                  focusNode: _goalFocusNode,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Goal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _focusNext(_unitFocusNode),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: widget.unitController,
                  focusNode: _unitFocusNode,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    hintText: 'e.g pages',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
