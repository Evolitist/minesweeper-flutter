import 'package:flutter/rendering.dart';
import 'package:minesweeper/constants.dart';
import 'package:minesweeper/gestures.dart';

const BoxDecoration _kOpenDecor = BoxDecoration(
  border: Border.fromBorderSide(BorderSide(width: 0.5, color: kGray700)),
  color: kGray400,
);
const BoxDecoration _kClosedDecor = BoxDecoration(
  border: Border(
    top: BorderSide(width: 4, color: kGray300),
    left: BorderSide(width: 4, color: kGray300),
    bottom: BorderSide(width: 4, color: kGray700),
    right: BorderSide(width: 4, color: kGray700),
  ),
  color: kGray500,
);
const BoxDecoration _kRedOpenDecor = BoxDecoration(
  border: Border.fromBorderSide(BorderSide(width: 0.5, color: kGray700)),
  color: kRed400,
);
const BoxDecoration _kRedClosedDecor = BoxDecoration(
  border: Border(
    top: BorderSide(width: 4, color: kRed300),
    left: BorderSide(width: 4, color: kRed300),
    bottom: BorderSide(width: 4, color: kRed700),
    right: BorderSide(width: 4, color: kRed700),
  ),
  color: kRed500,
);

final List<TextPainter> _kPainters = [
  TextPainter(text: TextSpan(text: '1', style: TextStyle(color: Color(0xff0000ff), fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: '2', style: TextStyle(color: Color(0xff008000), fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: '3', style: TextStyle(color: Color(0xffff0000), fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: '4', style: TextStyle(color: Color(0xff000080), fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: '5', style: TextStyle(color: Color(0xff800000), fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: '6', style: TextStyle(color: Color(0xff008080), fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: '7', style: TextStyle(color: Color(0xff808000), fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: '8', style: TextStyle(color: Color(0xff800080), fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: String.fromCharCode(0xe5cd), style: TextStyle(color: Color(0xff000000), fontSize: 28, fontFamily: 'MaterialIcons')), textDirection: TextDirection.ltr),
  TextPainter(text: TextSpan(text: String.fromCharCode(0xe153), style: TextStyle(color: Color(0xff000000), fontSize: 24, fontFamily: 'MaterialIcons')), textDirection: TextDirection.ltr),
];

class RenderField extends RenderBox {
  RenderField({
    int gameState,
    List<int> states,
    ValueChanged<int> onTap,
    ValueChanged<int> onLongTap,
  }) :  _gameState = gameState,
        _states = states,
        onTap = onTap,
        onLongTap = onLongTap {
    for (var child in _children) {
      adoptChild(child);
    }
  }

  List<int> get states => _states;
  List<int> _states;
  set states(List<int> newStates) {
    assert(newStates != null);
    assert(newStates.length == states.length);
    //if (_states == newStates) return;
    for (int i = 0; i < kCount; ++i) {
      int ns = newStates[i];
      if (ns != states[i] && _children[i] != null) {
        _children[i].state = ns;
      }
    }
    _states = newStates;
  }

  ValueChanged<int> onTap;

  ValueChanged<int> onLongTap;

  int get gameState => _gameState;
  int _gameState = 3;
  set gameState(int gs) {
    _gameState = gs;
    if (gs == 2) {
      for (int i = 0; i < kCount; ++i) {
        if (states[i] & 48 > 0 && _children[i] != null) {
          _children[i].markNeedsPaint();
        }
      }
    }/* else if (gs == 3) {
      for (int i = 0; i < _kCount; ++i) {
        if (states[i] & 48 > 0 && _children[i] != null) {
          _children[i].markNeedsPaint();
        }
      }
    }*/
  }

  final List<RenderCell> _children = List.generate(kCount, (_) => RenderCell());
  double single;

  bool get sizedByParent => true;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! FieldCellParentData)
      child.parentData = FieldCellParentData();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    for (RenderBox child in _children) {
      if (child != null)
        visitor(child);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _children)
      child?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    for (RenderBox child in _children)
      child?.detach();
  }

  @override
  void performResize() {
    size = constraints.biggest;
    assert(size.isFinite);
    single = size.width / kWidth;
  }

  @override
  void performLayout() {
    for (var tp in _kPainters) {
      tp.layout();
    }
    for (int i = 0; i < kCount; ++i) {
      final child = _children[i];
      final pd = child.parentData;
      if (pd is FieldCellParentData) {
        pd.pos = i;
        pd.i = i % kWidth;
        pd.j = i ~/ kWidth;
        pd.offset = Offset(single * pd.i, single * pd.j);
      }
      child.state = _states[i];
      child.layout(BoxConstraints.tight(Size.square(single)));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (var child in _children) {
      final BoxParentData pd = child.parentData;
      context.paintChild(child, offset + pd.offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    for (int index = _children.length - 1; index >= 0; index -= 1) {
      final RenderBox child = _children[index];
      if (child != null) {
        final BoxParentData childParentData = child.parentData;
        final bool isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(transformed == position - childParentData.offset);
            return child.hitTest(result, position: transformed);
          },
        );
        if (isHit)
          return true;
      }
    }
    return false;
  }
}

class FieldCellParentData extends BoxParentData {
  int pos;
  int i;
  int j;
}

class RenderCell extends RenderBox {
  final TapGestureRecognizer tapRecognizer = TapGestureRecognizer();
  final LongTapGestureRecognizer longTapRecognizer = LongTapGestureRecognizer();

  int get state => _state;
  int _state;
  set state(int ns) {
    assert(ns != null);
    _state = ns;
    markNeedsPaint();
  }

  RenderField get field => parent;

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  void performResize() => size = constraints.biggest;

  @override
  void performLayout() {
    if (parent is RenderField) {
      final FieldCellParentData pd = parentData;
      tapRecognizer.onTap = () => field.onTap(pd.pos);
      longTapRecognizer.onLongPress = () => field.onLongTap(pd.pos);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final int gameState = field.gameState;
    BoxDecoration decor = _kClosedDecor;
    if (gameState == 2) {
      if (state & 32 > 0 && state & 15 < 9) decor = _kRedClosedDecor;
      else if (state & 15 > 8 && state & 16 == 0) decor = _kRedOpenDecor;
      else decor = state & 16 > 0 ? _kClosedDecor : _kOpenDecor;
    } else {
      decor = state & 16 > 0 ? _kClosedDecor : _kOpenDecor;
    }
    decor?.createBoxPainter()?.paint(
      context.canvas,
      offset,
      ImageConfiguration(size: size, textDirection: TextDirection.ltr),
    );
    TextPainter tp;
    if (state > 0 && state < 9) {
      tp = _kPainters[state - 1];
    } else if (state & 32 > 0) {
      tp = _kPainters[9];
    } else if (state & 15 > 8 && (state & 16 == 0 || gameState == 2)) {
      tp = _kPainters[8];
    }
    tp?.paint(context.canvas, offset + Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool hitTestSelf(Offset position) => size.contains(position);

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      tapRecognizer.addPointer(event);
      longTapRecognizer.addPointer(event);
    }
  }
}


