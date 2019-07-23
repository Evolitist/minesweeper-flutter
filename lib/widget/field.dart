import 'package:flutter/widgets.dart' show LeafRenderObjectWidget, Key, BuildContext, ValueChanged;
import 'package:minesweeper/render/field.dart';

class FieldRenderObject extends LeafRenderObjectWidget {
  final int gameState;
  final List<int> states;
  final ValueChanged<int> onTap;
  final ValueChanged<int> onLongTap;

  const FieldRenderObject({Key key, this.gameState = 3, this.states, this.onTap, this.onLongTap}) : super(key: key);

  @override
  RenderField createRenderObject(BuildContext context) {
    return RenderField(gameState: gameState, states: states, onTap: onTap, onLongTap: onLongTap);
  }

  @override
  void updateRenderObject(BuildContext context, RenderField renderObject) {
    renderObject
      ..gameState = gameState
      ..states = states
      ..onTap = onTap
      ..onLongTap = onLongTap;
  }
}
