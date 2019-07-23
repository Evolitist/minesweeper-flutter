import 'package:flutter/gestures.dart';

export 'package:flutter/gestures.dart' show TapGestureRecognizer;

class LongTapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  LongTapGestureRecognizer({
    Duration deadline = const Duration(milliseconds: 150),
    double postAcceptSlopTolerance,
    PointerDeviceKind kind,
    Object debugOwner,
  }) : super(
    deadline: deadline,
    postAcceptSlopTolerance: postAcceptSlopTolerance,
    kind: kind,
    debugOwner: debugOwner,
  );

  bool _longPressAccepted = false;
  OffsetPair _longPressOrigin;
  int _initialButtons;
  GestureLongPressCallback onLongPress;
  GestureLongPressStartCallback onLongPressStart;
  GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  GestureLongPressUpCallback onLongPressUp;
  GestureLongPressEndCallback onLongPressEnd;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        if (onLongPressStart == null &&
            onLongPress == null &&
            onLongPressMoveUpdate == null &&
            onLongPressEnd == null &&
            onLongPressUp == null)
          return false;
        break;
      default:
        return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    super.acceptGesture(primaryPointer);
    _checkLongPressStart();
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (_longPressAccepted == true) {
        _checkLongPressEnd(event);
      } else {
        resolve(GestureDisposition.rejected);
      }
      _reset();
    } else if (event is PointerCancelEvent) {
      _reset();
    } else if (event is PointerDownEvent) {
      _longPressOrigin = OffsetPair.fromEventPosition(event);
      _initialButtons = event.buttons;
    } else if (event is PointerMoveEvent) {
      if (event.buttons != _initialButtons) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(primaryPointer);
      } else if (_longPressAccepted) {
        _checkLongPressMoveUpdate(event);
      }
    }
  }

  void _checkLongPressStart() {
    assert(_initialButtons == kPrimaryButton);
    final LongPressStartDetails details = LongPressStartDetails(
      globalPosition: _longPressOrigin.global,
      localPosition: _longPressOrigin.local,
    );
    if (onLongPressStart != null)
      invokeCallback<void>('onLongPressStart',
              () => onLongPressStart(details));
    if (onLongPress != null)
      invokeCallback<void>('onLongPress', onLongPress);
  }

  void _checkLongPressMoveUpdate(PointerEvent event) {
    assert(_initialButtons == kPrimaryButton);
    final LongPressMoveUpdateDetails details = LongPressMoveUpdateDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      offsetFromOrigin: event.position - _longPressOrigin.global,
      localOffsetFromOrigin: event.localPosition - _longPressOrigin.local,
    );
    if (onLongPressMoveUpdate != null)
      invokeCallback<void>('onLongPressMoveUpdate',
              () => onLongPressMoveUpdate(details));
  }

  void _checkLongPressEnd(PointerEvent event) {
    assert(_initialButtons == kPrimaryButton);
    final LongPressEndDetails details = LongPressEndDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
    );
    if (onLongPressEnd != null)
      invokeCallback<void>('onLongPressEnd', () => onLongPressEnd(details));
    if (onLongPressUp != null)
      invokeCallback<void>('onLongPressUp', onLongPressUp);
  }

  void _reset() {
    _longPressAccepted = false;
    _longPressOrigin = null;
    _initialButtons = null;
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_longPressAccepted && disposition == GestureDisposition.rejected) {
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void acceptGesture(int pointer) {}

  @override
  String get debugDescription => 'long press';
}
