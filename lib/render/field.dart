import 'package:flutter/rendering.dart';
import 'package:minesweeper/constants.dart';
import 'package:minesweeper/gestures.dart';

const TextDirection _kd = TextDirection.ltr;
const FontWeight _kw = FontWeight.bold;
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

const Map<String, TextStyle> _kSymbols = {
  '1': TextStyle(color: Color(0xff0000ff), fontWeight: _kw),
  '2': TextStyle(color: Color(0xff008000), fontWeight: _kw),
  '3': TextStyle(color: Color(0xffff0000), fontWeight: _kw),
  '4': TextStyle(color: Color(0xff000080), fontWeight: _kw),
  '5': TextStyle(color: Color(0xff800000), fontWeight: _kw),
  '6': TextStyle(color: Color(0xff008080), fontWeight: _kw),
  '7': TextStyle(color: Color(0xff808000), fontWeight: _kw),
  '8': TextStyle(color: Color(0xff800080), fontWeight: _kw),
  '\ue5cd': TextStyle(color: Color(0xff000000), fontFamily: 'MaterialIcons'),
  '\ue153': TextStyle(color: Color(0xff000000), fontFamily: 'MaterialIcons'),
};

class RenderField extends RenderBox {
  RenderField({
    int gameState,
    List<int> states,
    double cellSize,
    int width,
    this.onTap,
    this.onLongTap,
  }) :  _gameState = gameState,
        _states = states,
        _cellSize = cellSize,
        _width = width {
    _painters = _kSymbols.entries.map((e) {
      return TextPainter(
        text: TextSpan(text: e.key, style: e.value.copyWith(fontSize: cellSize * 0.8)),
        textDirection: _kd,
      )..layout();
    }).toList(growable: false);
    _children = List.generate(states.length, (_) => RenderCell(), growable: false);
    for (var child in _children) {
      adoptChild(child);
    }
  }

  ValueChanged<int> onTap;

  ValueChanged<int> onLongTap;

  List<int> get states => _states;
  List<int> _states;
  set states(List<int> newStates) {
    assert(newStates != null);
    if (newStates.length == states.length) {
      for (int i = 0; i < newStates.length; ++i) {
        int ns = newStates[i];
        if (ns != states[i] && _children[i] != null) {
          _children[i].state = ns;
        }
      }
      _states = newStates;
    } else {
      for (var child in _children) {
        dropChild(child);
      }
      _states = newStates;
      _children = List.generate(states.length, (_) => RenderCell(), growable: false);
      for (var child in _children) {
        adoptChild(child);
      }
      markNeedsLayout();
    }
  }

  int get gameState => _gameState;
  int _gameState = 3;
  set gameState(int gs) {
    _gameState = gs;
    if (gs == 2) {
      for (int i = 0; i < states.length; ++i) {
        if (states[i] & 48 > 0 && _children[i] != null) {
          _children[i].markNeedsPaint();
        }
      }
    }
  }

  double get cellSize => _cellSize;
  double _cellSize;
  set cellSize(double newSize) {
    assert(newSize != null);
    if (_cellSize == newSize) return;
    _cellSize = newSize;
    _painters = _kSymbols.entries.map((e) {
      return TextPainter(
        text: TextSpan(text: e.key, style: e.value.copyWith(fontSize: cellSize * 0.8)),
        textDirection: _kd,
      )..layout();
    }).toList(growable: false);
    markNeedsLayout();
  }

  int get width => _width;
  int _width;
  set width(int newWidth) {
    assert(newWidth != null);
    if (_width == newWidth) return;
    _width = newWidth;
    markNeedsLayout();
  }

  List<TextPainter> _painters;
  List<RenderCell> _children;

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
  void performLayout() {
    double w = cellSize * width;
    double gap = constraints.biggest.width - w;
    size = Size(w, constraints.constrainHeight(states.length / width * cellSize + gap / 2));
    for (int i = 0; i < _children.length; ++i) {
      final child = _children[i];
      final pd = child.parentData;
      if (pd is FieldCellParentData) {
        pd.pos = i;
        pd.i = i % width;
        pd.j = i ~/ width;
        pd.painters = _painters;
        pd.offset = Offset(cellSize * pd.i, cellSize * pd.j);
      }
      child.state = _states[i];
      child.layout(BoxConstraints.tight(Size.square(cellSize)));
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
  List<TextPainter> painters;
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

  List<TextPainter> painters;

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
      painters = pd.painters;
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
      tp = painters[state - 1];
    } else if (state & 32 > 0) {
      tp = painters[9];
    } else if (state & 15 > 8 && (state & 16 == 0 || gameState == 2)) {
      tp = painters[8];
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


