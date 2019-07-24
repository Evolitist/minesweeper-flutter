import 'dart:async' show Timer;
import 'dart:math' show Random;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, SystemChrome, SystemUiOverlayStyle, DeviceOrientation;

import 'package:minesweeper/constants.dart';
import 'package:minesweeper/widget/counter.dart';
import 'package:minesweeper/widget/field.dart';

/// STATES
/// 0..8 = empty
/// 8..15 = mine
///
/// FLAGS
/// 16 (0b00010000) = hidden
/// 32 (0b00100000) = flag

void main() async {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MaterialApp(
    title: 'Minesweeper',
    color: const Color(0xffffffff),
    theme: ThemeData.dark(),
    onGenerateRoute: (_) => PageRouteBuilder(pageBuilder: (ctx, aIn, aOut) => const Screen()),
    debugShowCheckedModeBanner: false,
  ));
}

class Screen extends StatefulWidget {
  const Screen({Key key}) : super(key: key);
  
  @override
  _ScreenState createState() => _ScreenState();

  static ValueNotifier<int> state(BuildContext context) {
    _ScreenState ss = context.ancestorStateOfType(TypeMatcher<_ScreenState>());
    return ss._state;
  }

  static Listenable resetter(BuildContext context) {
    _ScreenState ss = context.ancestorStateOfType(TypeMatcher<_ScreenState>());
    return ss._resetter;
  }
}

class _ScreenState extends State<Screen> with WidgetsBindingObserver {
  final KeepAliveHandle _resetter = KeepAliveHandle();
  final ValueNotifier<int> _mines = ValueNotifier(0);
  final ValueNotifier<int> _time = ValueNotifier(0);
  final ValueNotifier<int> _state = ValueNotifier(3);
  int _totalMines;
  int _delta = 1;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.renderView.automaticSystemUiAdjustment = false;
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: const Color(0),
      systemNavigationBarColor: kGray400,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _delta = 0;
    if (state == AppLifecycleState.resumed) _delta = 1;
  }

  void _showWinMessage() {
    final String minutes = '${_time.value ~/ 60}'.padLeft(2, '0');
    final String seconds = '${_time.value % 60}'.padLeft(2, '0');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('You won!'),
          content: Text('$minutes:$seconds'),
          actions: <Widget>[
            FlatButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    _timer?.cancel();
    _mines.value = _totalMines ?? 0;
    _time.value = 0;
    _state.value = 3;
    _resetter.release();
  }

  void _requestRestart() {
    if (_state.value > 0) {
      _resetGame();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Restart?'),
          actions: <Widget>[
            FlatButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(ctx, false);
              },
            ),
            FlatButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(ctx, true);
              },
            ),
          ],
        );
      },
    ).then((b) {
      if (b == true) {
        _resetGame();
      }
    });
  }

  Widget _buildCounter(BuildContext context, ValueNotifier<int> counter) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 82, maxHeight: 60),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: kGray900,
          border: Border(
            top: BorderSide(width: 4, color: kGray700),
            left: BorderSide(width: 4, color: kGray700),
            bottom: BorderSide(width: 4, color: kGray300),
            right: BorderSide(width: 4, color: kGray300),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DigitalCounter(counter: counter),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGray400,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const SizedBox(height: 58, width: double.infinity),
                  StatusIndicator(
                    status: _state,
                    onTap: () {
                      if (_state.value < 3) _requestRestart();
                    },
                  ),
                  Positioned(
                    left: 16,
                    width: 80,
                    height: 48,
                    child: _buildCounter(context, _time),
                  ),
                  Positioned(
                    right: 16,
                    width: 80,
                    height: 48,
                    child: _buildCounter(context, _mines),
                  ),
                ],
              ),
            ),
          ),
          RepaintBoundary(
            child: NotificationListener<BaseNotification>(
              onNotification: (n) {
                if (n is FirstOpenNotification) {
                  _state.value = 0;
                  _timer = Timer.periodic(const Duration(seconds: 1), (i) {
                    if (_time.value < 999) _time.value += _delta;
                  });
                } else if (n is FlagNotification) {
                  _mines.value += n.md;
                } else if (n is WinNotification && _state.value != 1) {
                  _state.value = 1;
                  _timer?.cancel();
                  _mines.value = 0;
                  _showWinMessage();
                } else if (n is LoseNotification && _state.value != 2) {
                  _state.value = 2;
                  _timer?.cancel();
                } else if (n is ResetNotification) {
                  _totalMines = n.mines;
                  WidgetsBinding.instance.addPostFrameCallback((_) => _resetGame());
                }
                return true;
              },
              child: ValueListenableBuilder<int>(
                valueListenable: _state,
                builder: (context, data, child) {
                  return const Center(child: FieldController(cellSize: 30));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BaseNotification extends Notification {}
class FirstOpenNotification extends BaseNotification {}
class FlagNotification extends BaseNotification {
  final int md;

  FlagNotification(this.md);
}
class WinNotification extends BaseNotification {}
class LoseNotification extends BaseNotification {}
class ResetNotification extends BaseNotification {
  final int mines;

  ResetNotification(this.mines);
}

class StatusIndicator extends StatelessWidget {
  final ValueNotifier<int> status;
  final VoidCallback onTap;

  const StatusIndicator({Key key, this.status, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: ValueListenableBuilder<int>(
          valueListenable: status,
          builder: (context, data, child) {
            return Text(
              data & 1 == (data & 2) >> 1 ? '🙂' : data & 2 > 0 ? '😣' : '😎',
              textAlign: TextAlign.center,
              style: const TextStyle(inherit: false, fontSize: 40),
            );
          },
        ),
      ),
    );
  }
}


class DigitalCounter extends StatelessWidget {
  final ValueNotifier<int> counter;

  const DigitalCounter({Key key, this.counter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: counter,
        builder: (ctx, data, child) {
          return CounterRenderObject(
            height: 32,
            value: data.clamp(0, 999).toString().padLeft(3, '0'),
          );
        },
      ),
    );
  }
}

class FieldController extends StatefulWidget {
  const FieldController({Key key, this.cellSize = 30}) : super(key: key);

  final double cellSize;

  @override
  _FieldControllerState createState() => _FieldControllerState();
}

class _FieldControllerState extends State<FieldController> {
  final Random random = Random();
  List<int> _kNeighbors;
  Uint8List _states;
  Set<int> _noRelocate = Set();
  bool _accepting = true;
  bool _gotZero = false;
  int _falseMines = 0;
  int _actualMines;
  int _open = 0;
  int _width;
  int _count;
  int _mines;

  @override
  void initState() {
    super.initState();
    Screen.resetter(context).addListener(() {
      if (mounted) {
        _resetField();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }

  void _calcOptions() {
    int width = MediaQuery.of(context).size.width ~/ widget.cellSize;
    int height = (MediaQuery.of(context).size.height - 58 - MediaQuery.of(context).padding.top) ~/ widget.cellSize;
    int count = width * height;
    if (count != _count) {
      _width = width;
      _count = count;
      _mines = count ~/ 4.8;
      _kNeighbors = [-1, 1, -_width, _width, -_width-1, -_width+1, _width-1, _width+1];
      _states = Uint8List.fromList(List.filled(_count, 16, growable: false));
      ResetNotification(_mines).dispatch(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calcOptions();
  }

  @override
  void didUpdateWidget(FieldController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cellSize != widget.cellSize) {
      _calcOptions();
    }
  }

  int get state => Screen.state(context).value;

  void _triggerWin() {
    for (int j = 0; j < _count; ++j) {
      if (_states[j] & 15 > 8) {
        _states[j] |= 32;
      }
      if (_states[j] & 16 > 0) {
        _openAt(j, true);
      }
    }
    WinNotification().dispatch(context);
  }

  void _onTapCell(int i) {
    if (i < 0 || i >= _count) return;
    if (!_accepting) {
      _accepting = true;
      return;
    }
    int _state = state;
    if (_state & 1 == (_state & 2) >> 1 && _states[i] > 0) {
      HapticFeedback.vibrate();
    }
    _openAt(i);
    setState(() {});
  }

  void _onLongTapCell(int i) {
    if (i < 0) return;
    int state = _states[i];
    if (state & 16 == 0) return _onTapCell(i);
    HapticFeedback.vibrate();
    int md = _states[i] & 32 > 0 ? 1 : -1;
    FlagNotification(md).dispatch(context);
    int amd = _states[i] & 15 > 8 ? md : 0;
    int fmd = _states[i] & 15 > 8 ? 0 : md;
    _actualMines += amd;
    _falseMines += fmd;
    _states[i] ^= 32;
    if (_actualMines == 0 && _falseMines == 0) {
      _accepting = false;
      _triggerWin();
      Future.delayed(const Duration(milliseconds: 150), () => _accepting = true);
    }
    setState(() {});
  }

  void _resetField() {
    _gotZero = false;
    _noRelocate = Set();
    _falseMines = 0;
    _open = 0;
    _states.setAll(0, List.filled(_count, 16, growable: false));
  }

  void _fillField(int touchPoint) {
    Set<int> mines = {};
    while(mines.length < _mines) {
      int point = random.nextInt(_count);
      while(point == touchPoint) {
        point = random.nextInt(_count);
      }
      mines.add(point);
    }
    mines.forEach((i) {
      _states[i] = 25;
    });
    _actualMines = _mines;
  }

  bool _openAt(int t, [bool skipCascade = false]) {
    int _state = state;
    if (_state & 1 != (_state & 2) >> 1) {
      ResetNotification(_mines).dispatch(context);
      _resetField();
      return false;
    }
    if (t < 0 || t > _count - 1) return false;
    if (_state > 0) {
      FirstOpenNotification().dispatch(context);
      _fillField(t);
    }
    if (_states[t] == 0 || _states[t] & 32 > 0) {
      return false;
    }
    if (_states[t] & 15 > 8) {
      if (_gotZero || (_noRelocate?.contains(t) ?? true)) {
        LoseNotification().dispatch(context);
        _states[t] = 9;
        return true;
      } else {
        int newPos;
        do {
          newPos = random.nextInt(_count);
        } while(newPos == t || _states[newPos] & 15 > 8 || (_noRelocate?.contains(newPos) ?? false));
        _states[newPos] = 25;
        _states[t] = 16;
      }
    }
    _noRelocate?.add(t);
    int acc = 0, flags = 0;
    setFlags(int val) {
      acc += val & 15 > 8 ? 1 : 0;
      flags += (val & 32) >> 5;
    }
    int c = t % _width;
    Set<int> cn = Set();
    for (int a in _kNeighbors) {
      int nt = t + a;
      if (nt < 0 || nt >= _count) continue;
      int nc = nt % _width;
      if ((nc-c).abs() > 1) continue;
      _noRelocate?.add(nt);
      if (!skipCascade && _states[nt] & 16 > 0) {
        cn.add(nt);
      }
      setFlags(_states[nt]);
    }
    if (acc == 0) {
      _gotZero = true;
      _noRelocate = null;
    }
    if (_states[t] & 16 > 0) {
      ++_open;
    }
    _states[t] = acc;
    if (!skipCascade) {
      if (_open == _count - _mines) {
        _triggerWin();
        return true;
      }
      if (acc == flags) {
        for (int nt in cn) {
          if (_openAt(nt)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FieldRenderObject(
      gameState: state,
      states: List.of(_states),
      cellSize: widget.cellSize,
      width: _width,
      onTap: _onTapCell,
      onLongTap: _onLongTapCell,
    );
  }
}
