import 'package:flutter/widgets.dart' show LeafRenderObjectWidget, Key, BuildContext, required;
import 'package:minesweeper/render/counter.dart';

class CounterRenderObject extends LeafRenderObjectWidget {
  final int digits;
  final double height;
  final double spacing;
  final String value;

  CounterRenderObject({
    Key key,
    @required this.value,
    this.digits = 3,
    this.height = 32,
    this.spacing = 4,
  }) : super(key: key);

  @override
  RenderCounter createRenderObject(BuildContext context) {
    return RenderCounter(
      value: value,
      digits: digits,
      height: height,
      spacing: spacing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCounter renderObject) {
    renderObject
      ..value = value
      ..height = height
      ..spacing = spacing;
  }
}
