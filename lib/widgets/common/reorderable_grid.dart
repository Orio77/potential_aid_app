import 'package:flutter/material.dart';

/// A reorderable grid widget that supports drag and drop reordering
/// using long press gestures. This widget provides smooth animations
/// and visual feedback during the reordering process.
class ReorderableGrid<T> extends StatefulWidget {
  /// The list of data items to display in the grid
  final List<T> data;

  /// Number of columns in the grid
  final int crossAxisCount;

  /// Aspect ratio of each grid item (width/height)
  final double childAspectRatio;

  /// Layout constraints from parent widget
  final BoxConstraints constraints;

  /// Callback triggered when items are reordered
  final Function(int oldIndex, int newIndex) onReorder;

  /// Callback triggered when an item is tapped
  final Function(BuildContext context, T item) onTap;

  /// Builder function to create each grid item
  final Widget Function(T item) itemBuilder;

  /// Optional padding around the grid
  final EdgeInsetsGeometry padding;

  /// Spacing between grid items horizontally
  final double spacing;

  /// Spacing between grid items vertically
  final double runSpacing;

  const ReorderableGrid({
    super.key,
    required this.data,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.constraints,
    required this.onReorder,
    required this.onTap,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16.0),
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  State<ReorderableGrid<T>> createState() => _ReorderableGridState<T>();
}

class _ReorderableGridState<T> extends State<ReorderableGrid<T>> {
  int? _draggingIndex;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final itemWidth =
        (widget.constraints.maxWidth -
            widget.padding.horizontal -
            (widget.spacing * (widget.crossAxisCount - 1))) /
        widget.crossAxisCount;
    final itemHeight = itemWidth / widget.childAspectRatio;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Padding(
        padding: widget.padding,
        child: Wrap(
          spacing: widget.spacing,
          runSpacing: widget.runSpacing,
          children: List.generate(widget.data.length, (index) {
            final item = widget.data[index];
            final isDragging = _draggingIndex == index;
            final isHovered = _hoveredIndex == index;

            return DragTarget<int>(
              onAcceptWithDetails: (details) {
                if (details.data != index) {
                  widget.onReorder(details.data, index);
                }
                _resetDragState();
              },
              onWillAcceptWithDetails: (details) {
                setState(() {
                  _hoveredIndex = index;
                });
                return details.data != index;
              },
              onLeave: (data) {
                setState(() {
                  _hoveredIndex = null;
                });
              },
              builder: (context, candidateData, rejectedData) {
                return LongPressDraggable<int>(
                  data: index,
                  feedback: _buildDragFeedback(item, itemWidth, itemHeight),
                  childWhenDragging: _buildPlaceholder(itemWidth, itemHeight),
                  onDragStarted: () {
                    setState(() {
                      _draggingIndex = index;
                    });
                  },
                  onDragEnd: (details) {
                    _resetDragState();
                  },
                  child: _buildGridItem(
                    item,
                    itemWidth,
                    itemHeight,
                    isDragging,
                    isHovered,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  /// Builds the feedback widget shown while dragging
  Widget _buildDragFeedback(T item, double width, double height) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: height,
        child: Opacity(opacity: 0.8, child: widget.itemBuilder(item)),
      ),
    );
  }

  /// Builds the placeholder shown in the original position while dragging
  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
    );
  }

  /// Builds each grid item with proper styling and interactions
  Widget _buildGridItem(
    T item,
    double width,
    double height,
    bool isDragging,
    bool isHovered,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      transform: Matrix4.identity()
        ..scale(isHovered && !isDragging ? 1.05 : 1.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isHovered && !isDragging
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: InkWell(
          onTap: isDragging ? null : () => widget.onTap(context, item),
          child: widget.itemBuilder(item),
        ),
      ),
    );
  }

  /// Resets the drag state
  void _resetDragState() {
    setState(() {
      _draggingIndex = null;
      _hoveredIndex = null;
    });
  }
}
