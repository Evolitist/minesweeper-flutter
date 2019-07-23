import 'package:flutter/rendering.dart' show RenderBox, Paint, Offset, PaintingStyle, Size, Path, PaintingContext;
import 'package:minesweeper/constants.dart';

class RenderCounter extends RenderBox {
  static final RegExp _valueRegex = RegExp(r'\b[0-9]*\b');
  final Paint _paint = Paint()
    ..color = kRed400
    ..style = PaintingStyle.fill;
  final List<List<List<Offset>>> _polygonCache;
  final int zero = '0'.codeUnitAt(0);
  final int digits;
  double width;
  double thickness;
  double bigGap;
  double midGap;
  double smallGap;
  double smallPad;
  double bigPad;

  RenderCounter({
    String value,
    this.digits,
    double height,
    double spacing,
  }) :  assert(digits > 0),
        assert(value != null),
        assert(value.length == digits),
        assert(_valueRegex.hasMatch(value)),
        _value = value,
        _height = height,
        _spacing = spacing,
        _polygonCache = List.generate(digits, (_) => List(7));

  String get value => _value;
  String _value;
  set value(String newValue) {
    if (newValue == _value) return;
    assert(newValue != null);
    assert(newValue.length == digits);
    assert(_valueRegex.hasMatch(newValue));
    _value = newValue;
    markNeedsPaint();
  }

  double get height => _height;
  double _height;
  set height(double newVal) {
    assert(newVal != null);
    assert(newVal >= 12);
    _height = newVal;
    width = null;
    thickness = null;
    bigGap = null;
    midGap = null;
    smallGap = null;
    smallPad = null;
    bigPad = null;
    _polygonCache.setAll(0, List.generate(digits, (_) => List(7)));
    markNeedsLayout();
  }

  double get spacing => _spacing;
  double _spacing;
  set spacing(double newVal) {
    assert(newVal != null);
    assert(newVal >= 0);
    _spacing = newVal;
    _polygonCache.setAll(0, List.generate(digits, (_) => List(7)));
    markNeedsLayout();
  }

  @override
  void performLayout() {
    width ??= height / 2;
    size = Size(width * digits + spacing * (digits - 1), height);
    thickness ??= width / 5;
    bigGap ??= thickness * 2 / 3;
    midGap ??= thickness / 2;
    smallGap ??= thickness / 3;
    smallPad ??= thickness / 10;
    bigPad ??= smallGap + smallPad;
  }

  List<Offset> leftPolygon(double top, double bottom, double left) => [
    Offset(left + smallGap, top),
    Offset(left, top + smallGap),
    Offset(left, bottom - smallGap),
    Offset(left + smallGap, bottom),
    Offset(left + thickness, bottom - bigGap),
    Offset(left + thickness, top + bigGap),
  ];

  List<Offset> rightPolygon(double top, double bottom, double right) => [
    Offset(right - smallGap, top),
    Offset(right - thickness, top + bigGap),
    Offset(right - thickness, bottom - bigGap),
    Offset(right - smallGap, bottom),
    Offset(right, bottom - smallGap),
    Offset(right, top + smallGap),
    Offset(right - smallGap, top),
  ];

  @override
  void paint(PaintingContext context, Offset offset) {
    double dx = 0;
    for (int k = 0; k < digits; ++k) {
      final int i = _value.codeUnitAt(k);
      final int value = i - zero;
      final double left = dx;
      final double right = dx + width;
      Path p = Path();
      // Top
      if (value != 1 && value != 4) {
        if (_polygonCache[k][0] == null) {
          final tLeft = left + bigPad;
          final tRight = right - bigPad;
          _polygonCache[k][0] = [
            Offset(tLeft, smallGap),
            Offset(tLeft + smallGap, 0),
            Offset(tRight - smallGap, 0),
            Offset(tRight, smallGap),
            Offset(tRight - bigGap, thickness),
            Offset(tLeft + bigGap, thickness),
          ];
        }
        p.addPolygon(_polygonCache[k][0], true);
      }
      // Left Top
      if (value == 0 || (value > 3 && value != 7)) {
        if (_polygonCache[k][1] == null) {
          _polygonCache[k][1] = leftPolygon(bigPad, width - smallPad, left);
        }
        p.addPolygon(_polygonCache[k][1], true);
      }
      // Right Top
      if (value != 5 && value != 6) {
        if (_polygonCache[k][2] == null) {
          _polygonCache[k][2] = rightPolygon(bigPad, width - smallPad, right);
        }
        p.addPolygon(_polygonCache[k][2], true);
      }
      // Middle
      if (value > 1 && value != 7) {
        if (_polygonCache[k][3] == null) {
          final mLeft = left + bigPad;
          final mRight = right - bigPad;
          final halfThick = thickness / 2;
          _polygonCache[k][3] = [
            Offset(mLeft, width),
            Offset(mLeft + midGap, width - halfThick),
            Offset(mRight - midGap, width - halfThick),
            Offset(mRight, width),
            Offset(mRight - midGap, width + halfThick),
            Offset(mLeft + midGap, width + halfThick),
            Offset(mLeft, width),
          ];
        }
        p.addPolygon(_polygonCache[k][3], false);
      }
      // Left Bottom
      if (value == 0 || value == 2 || value == 6 || value == 8) {
        if (_polygonCache[k][4] == null) {
          _polygonCache[k][4] = leftPolygon(width + smallPad, height - bigPad, left);
        }
        p.addPolygon(_polygonCache[k][4], true);
      }
      // Right bottom
      if (value != 2) {
        if (_polygonCache[k][5] == null) {
          _polygonCache[k][5] = rightPolygon(width + smallPad, height - bigPad, right);
        }
        p.addPolygon(_polygonCache[k][5], true);
      }
      // Bottom
      if (value != 1 && value != 4 && value != 7) {
        if (_polygonCache[k][6] == null) {
          final bLeft = left + bigPad;
          final bRight = right - bigPad;
          _polygonCache[k][6] = [
            Offset(bLeft, height - smallGap),
            Offset(bLeft + bigGap, height - thickness),
            Offset(bRight - bigGap, height - thickness),
            Offset(bRight, height - smallGap),
            Offset(bRight - smallGap, height),
            Offset(bLeft + smallGap, height),
            Offset(bLeft, height - smallGap),
          ];
        }
        p.addPolygon(_polygonCache[k][6], false);
      }
      p.shift(offset);
      context.canvas.drawPath(p, _paint);
      dx += width + spacing;
    }
  }
}