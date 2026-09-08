import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _backgroundColor = Color(0xFF0F172A);
const _keypadColor = Color(0xFF111827);
const _numberButtonColor = Color(0xFF1E293B);
const _numberBorderColor = Color(0xFF334155);
const _operatorColor = Color(0xFF4F46E5);
const _secondaryTextColor = Color(0xFF94A3B8);
const _accentColor = Color(0xFF38BDF8);
const _divisionByZeroMessage = 'Cannot divide by zero';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: _backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Máy tính cơ bản',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: _backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _operatorColor,
          brightness: Brightness.dark,
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetInput = false;
  bool _justCalculated = false;
  bool _hasError = false;
  final FocusNode _keyboardFocusNode = FocusNode(
    debugLabel: 'Calculator keyboard shortcuts',
  );

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final logicalKey = event.logicalKey;
    if (logicalKey == LogicalKeyboardKey.escape) {
      _onButtonPressed('AC');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.backspace) {
      _onButtonPressed('backspace');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.numpadEnter) {
      _onButtonPressed('=');
      return KeyEventResult.handled;
    }

    final character = event.character;
    if (character != null && RegExp(r'^\d$').hasMatch(character)) {
      _onButtonPressed(character);
      return KeyEventResult.handled;
    }

    if (character == '-' || logicalKey == LogicalKeyboardKey.numpadSubtract) {
      _onButtonPressed('keyboardMinus');
      return KeyEventResult.handled;
    }
    if (character == '+' || logicalKey == LogicalKeyboardKey.numpadAdd) {
      _onButtonPressed('+');
      return KeyEventResult.handled;
    }
    if (character == '*' || logicalKey == LogicalKeyboardKey.numpadMultiply) {
      _onButtonPressed('×');
      return KeyEventResult.handled;
    }
    if (character == '/' || logicalKey == LogicalKeyboardKey.numpadDivide) {
      _onButtonPressed('÷');
      return KeyEventResult.handled;
    }
    if (character == '.' ||
        character == ',' ||
        logicalKey == LogicalKeyboardKey.numpadDecimal) {
      _onButtonPressed(',');
      return KeyEventResult.handled;
    }
    if (character == '=' || logicalKey == LogicalKeyboardKey.equal) {
      _onButtonPressed('=');
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (RegExp(r'^\d$').hasMatch(value)) {
        _inputNumber(value);
      } else if (value == ',') {
        _inputDecimal();
      } else if (const ['÷', '×', '−', '+'].contains(value)) {
        _setOperator(value);
      } else if (value == '=') {
        _calculate();
      } else if (value == 'AC') {
        _clear();
      } else if (value == '±') {
        _toggleSign();
      } else if (value == '%') {
        _percentage();
      } else if (value == '√') {
        _squareRoot();
      } else if (value == 'x²') {
        _square();
      } else if (value == 'keyboardMinus') {
        _inputNegativeOrSubtract();
      } else if (value == 'backspace') {
        _backspace();
      }
    });
  }

  void _inputNumber(String number) {
    if (_hasError || _justCalculated) {
      _prepareForNewCalculation();
    }

    if (_shouldResetInput) {
      _display = number;
      _shouldResetInput = false;
    } else if (_display == '0') {
      _display = number;
    } else if (_display == '-0') {
      _display = '-$number';
    } else if (_display.replaceAll(RegExp(r'[-,]'), '').length < 15) {
      _display += number;
    }

    _updatePendingExpression();
  }

  void _inputDecimal() {
    if (_hasError || _justCalculated) {
      _prepareForNewCalculation();
    }

    if (_shouldResetInput) {
      _display = '0,';
      _shouldResetInput = false;
    } else if (!_display.contains(',')) {
      _display += ',';
    }

    _updatePendingExpression();
  }

  void _setOperator(String newOperator) {
    if (_hasError) return;

    final currentValue = _parseDisplay();
    if (currentValue == null) return;

    // Nếu hai toán tử được nhấn liên tiếp, chỉ thay toán tử đang chờ.
    if (_operator != null && _firstOperand != null && _shouldResetInput) {
      _operator = newOperator;
      _expression = '${_formatResult(_firstOperand!)} $newOperator';
      return;
    }

    // Tính kết quả trung gian khi người dùng tiếp tục một chuỗi phép tính.
    if (_operator != null && _firstOperand != null) {
      final result = _performOperation(
        _firstOperand!,
        currentValue,
        _operator!,
      );
      if (result == null) {
        _showError(
          '$_expression =',
          message: _operationErrorMessage(_operator!, currentValue),
        );
        return;
      }
      _display = _formatResult(result);
    }

    _firstOperand = _parseDisplay();
    _operator = newOperator;
    _expression = '$_display $newOperator';
    _shouldResetInput = true;
    _justCalculated = false;
  }

  void _calculate() {
    if (_hasError ||
        _operator == null ||
        _firstOperand == null ||
        _shouldResetInput) {
      return;
    }

    final secondOperand = _parseDisplay();
    if (secondOperand == null) return;

    final firstText = _formatResult(_firstOperand!);
    final secondText = _display;
    final operatorText = _operator!;
    final result = _performOperation(
      _firstOperand!,
      secondOperand,
      operatorText,
    );

    _expression = '$firstText $operatorText $secondText =';
    if (result == null) {
      _showError(
        _expression,
        message: _operationErrorMessage(operatorText, secondOperand),
      );
      return;
    }

    _display = _formatResult(result);
    _firstOperand = null;
    _operator = null;
    _shouldResetInput = true;
    _justCalculated = true;
  }

  double? _performOperation(double first, double second, String operator) {
    double result;
    switch (operator) {
      case '+':
        result = first + second;
      case '−':
        result = first - second;
      case '×':
        result = first * second;
      case '÷':
        if (second == 0) return null;
        result = first / second;
      default:
        return null;
    }
    return result.isFinite ? result : null;
  }

  String _operationErrorMessage(String operator, double secondOperand) {
    if (operator == '÷' && secondOperand == 0) {
      return _divisionByZeroMessage;
    }
    return 'Error';
  }

  void _inputNegativeOrSubtract() {
    if (_hasError) {
      _prepareForNewCalculation();
      _display = '-0';
      return;
    }

    final isStartingFirstOperand =
        _operator == null &&
        _firstOperand == null &&
        !_justCalculated &&
        _display == '0' &&
        _expression.isEmpty;
    final isStartingSecondOperand =
        _operator != null && _firstOperand != null && _shouldResetInput;

    if (isStartingFirstOperand || isStartingSecondOperand) {
      _display = '-0';
      _shouldResetInput = false;
      _justCalculated = false;
      _updatePendingExpression();
      return;
    }

    _setOperator('−');
  }

  void _toggleSign() {
    if (_hasError) return;

    if (_operator != null && _firstOperand != null && _shouldResetInput) {
      _display = '-0';
      _shouldResetInput = false;
      _updatePendingExpression();
      return;
    }

    if (_display == '0') {
      if (!_justCalculated) _display = '-0';
      return;
    }

    if (_display.startsWith('-')) {
      _display = _display.substring(1);
    } else {
      _display = '-$_display';
    }
    _updatePendingExpression();
  }

  void _percentage() {
    if (_hasError) return;

    if (_shouldResetInput && _operator != null) {
      _display = '0';
      _shouldResetInput = false;
    }

    final value = _parseDisplay();
    if (value == null) return;

    final originalValue = _display;
    _display = _formatResult(value / 100);

    if (_operator != null && _firstOperand != null) {
      _shouldResetInput = false;
      _updatePendingExpression();
    } else {
      _expression = '$originalValue %';
      _shouldResetInput = true;
      _justCalculated = true;
    }
  }

  void _squareRoot() {
    if (_hasError || (_shouldResetInput && _operator != null)) return;

    final value = _parseDisplay();
    if (value == null) return;

    final originalValue = _display;
    final operationText = '√$originalValue';
    if (value < 0) {
      final errorExpression = _operator != null && _firstOperand != null
          ? '${_formatResult(_firstOperand!)} $_operator $operationText ='
          : '$operationText =';
      _showError(errorExpression, message: 'Invalid input');
      return;
    }

    _applyUnaryResult(math.sqrt(value), operationText);
  }

  void _square() {
    if (_hasError || (_shouldResetInput && _operator != null)) return;

    final value = _parseDisplay();
    if (value == null) return;

    final originalValue = _display;
    final operationText = value < 0 ? '($originalValue)²' : '$originalValue²';
    final result = value * value;
    if (!result.isFinite) {
      _showError('$operationText =', message: 'Error');
      return;
    }

    _applyUnaryResult(result, operationText);
  }

  void _applyUnaryResult(double result, String operationText) {
    _display = _formatResult(result);
    if (_operator != null && _firstOperand != null) {
      _shouldResetInput = false;
      _justCalculated = false;
      _updatePendingExpression();
    } else {
      _expression = '$operationText =';
      _shouldResetInput = true;
      _justCalculated = true;
    }
  }

  void _backspace() {
    if (_hasError) {
      _clear();
      return;
    }
    if (_shouldResetInput) return;

    if (_display.length <= 1 ||
        (_display.startsWith('-') && _display.length <= 2)) {
      _display = '0';
    } else {
      _display = _display.substring(0, _display.length - 1);
    }
    _updatePendingExpression();
  }

  void _clear() {
    _display = '0';
    _expression = '';
    _firstOperand = null;
    _operator = null;
    _shouldResetInput = false;
    _justCalculated = false;
    _hasError = false;
  }

  void _prepareForNewCalculation() {
    _clear();
  }

  void _showError(String expression, {required String message}) {
    _display = message;
    _expression = expression;
    _firstOperand = null;
    _operator = null;
    _shouldResetInput = true;
    _justCalculated = false;
    _hasError = true;
  }

  void _updatePendingExpression() {
    if (_operator != null && _firstOperand != null && !_shouldResetInput) {
      _expression = '${_formatResult(_firstOperand!)} $_operator $_display';
    }
  }

  double? _parseDisplay() {
    return double.tryParse(_display.replaceAll(',', '.'));
  }

  String _formatResult(double value) {
    if (!value.isFinite) return 'Error';

    // Giới hạn sai số double và bỏ phần thập phân không cần thiết.
    final normalized = value.abs() < 1e-12
        ? 0.0
        : double.parse(value.toStringAsPrecision(12));
    var text = normalized.toString();
    if (text.endsWith('.0')) {
      text = text.substring(0, text.length - 2);
    }
    return text.replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: _backgroundColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final compactHeight = constraints.maxHeight < 700;
                final veryCompactHeight = constraints.maxHeight < 520;
                final pagePadding = isNarrow ? 12.0 : 20.0;
                final keypadPadding = isNarrow ? 12.0 : 16.0;
                final gap = veryCompactHeight
                    ? 6.0
                    : compactHeight || isNarrow
                    ? 8.0
                    : 10.0;
                final studentTopPadding = veryCompactHeight
                    ? 4.0
                    : compactHeight
                    ? 6.0
                    : 12.0;
                final studentBottomPadding = veryCompactHeight
                    ? 2.0
                    : compactHeight
                    ? 4.0
                    : 6.0;
                final studentVerticalPadding = veryCompactHeight
                    ? 4.0
                    : compactHeight
                    ? 6.0
                    : 8.0;
                final keypadTopPadding = veryCompactHeight
                    ? 6.0
                    : compactHeight
                    ? 10.0
                    : 16.0;
                final keypadBottomPadding = veryCompactHeight
                    ? 6.0
                    : compactHeight
                    ? 8.0
                    : 12.0;
                final keypadWidth = constraints.maxWidth - keypadPadding * 2;
                final keyWidth = (keypadWidth - gap * 3) / 4;

                // Reserve enough room for both display lines before sizing the
                // six keypad rows. This matters most on wide, short web views,
                // where button width no longer limits button height.
                const keypadRowCount = 6;
                final studentHeightBudget = veryCompactHeight
                    ? 30.0
                    : compactHeight
                    ? 38.0
                    : 50.0;
                final displayHeightBudget = veryCompactHeight
                    ? 70.0
                    : compactHeight
                    ? 96.0
                    : 132.0;
                final desiredKeyHeight = veryCompactHeight
                    ? 56.0
                    : compactHeight
                    ? 72.0
                    : 78.0;
                final availableKeyHeight =
                    (constraints.maxHeight -
                        studentHeightBudget -
                        displayHeightBudget -
                        1 -
                        keypadTopPadding -
                        keypadBottomPadding -
                        gap * (keypadRowCount - 1)) /
                    keypadRowCount;
                final keyHeight = math.max(
                  40.0,
                  math.min(
                    desiredKeyHeight,
                    math.min(keyWidth * 0.95, availableKeyHeight),
                  ),
                );

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding,
                        studentTopPadding,
                        pagePadding,
                        studentBottomPadding,
                      ),
                      child: _buildStudentInfo(
                        verticalPadding: studentVerticalPadding,
                      ),
                    ),
                    Expanded(
                      child: _buildDisplay(
                        isNarrow,
                        compactHeight: compactHeight,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    _buildKeypad(
                      keyHeight: keyHeight,
                      gap: gap,
                      horizontalPadding: keypadPadding,
                      topPadding: keypadTopPadding,
                      bottomPadding: keypadBottomPadding,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfo({required double verticalPadding}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: const Color(0xCC1E293B),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x99334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  const TextSpan(
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    children: [
                      TextSpan(text: 'MSSV: '),
                      TextSpan(
                        text: '2324801030073',
                        style: TextStyle(
                          color: Color(0xFF7DD3FC),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' • NGUYỄN XUÂN TRƯỜNG'),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay(bool isNarrow, {required bool compactHeight}) {
    return Semantics(
      liveRegion: true,
      label: 'Màn hình máy tính',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desiredTopPadding = compactHeight ? 4.0 : 8.0;
          final desiredBottomPadding = compactHeight ? 8.0 : 18.0;
          final desiredVerticalPadding =
              desiredTopPadding + desiredBottomPadding;
          final paddingScale = math.min(
            1.0,
            constraints.maxHeight / desiredVerticalPadding,
          );
          final topPadding = desiredTopPadding * paddingScale;
          final bottomPadding = desiredBottomPadding * paddingScale;
          final availableHeight = math.max(
            0.0,
            constraints.maxHeight - topPadding - bottomPadding,
          );
          final desiredGap = compactHeight ? 3.0 : 5.0;
          final displayGap = math.min(desiredGap, availableHeight * 0.05);
          final linesHeight = math.max(0.0, availableHeight - displayGap);
          final desiredExpressionHeight = compactHeight ? 20.0 : 24.0;
          final expressionHeight = math.min(
            desiredExpressionHeight,
            linesHeight * 0.3,
          );
          final resultHeight = math.max(0.0, linesHeight - expressionHeight);
          final resultFontSize = _hasError
              ? compactHeight
                    ? (isNarrow ? 24.0 : 28.0)
                    : (isNarrow ? 26.0 : 32.0)
              : compactHeight
              ? (isNarrow ? 42.0 : 48.0)
              : (isNarrow ? 48.0 : 56.0);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              isNarrow ? 16 : 24,
              topPadding,
              24,
              bottomPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: expressionHeight,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _expression,
                        key: const Key('calculator_expression'),
                        maxLines: 1,
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: compactHeight ? 15 : 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: displayGap),
                SizedBox(
                  height: resultHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _display,
                              key: const Key('calculator_display'),
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: resultFontSize,
                                fontWeight: _hasError
                                    ? FontWeight.bold
                                    : FontWeight.w300,
                                height: 1,
                                letterSpacing: _hasError ? -0.4 : -1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        width: 3,
                        height: math.min(
                          isNarrow ? 40 : 48,
                          resultHeight * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeypad({
    required double keyHeight,
    required double gap,
    required double horizontalPadding,
    required double topPadding,
    required double bottomPadding,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: _keypadColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildKeypadRow(
            keyHeight: keyHeight,
            gap: gap,
            buttons: [
              _buildButton('AC', 'ac', _ButtonKind.clear),
              _buildButton('±', 'sign', _ButtonKind.function),
              _buildButton('%', 'percent', _ButtonKind.function),
              _buildButton('÷', 'divide', _ButtonKind.operator),
            ],
          ),
          SizedBox(height: gap),
          _buildKeypadRow(
            keyHeight: keyHeight,
            gap: gap,
            spans: const [2, 2],
            buttons: [
              _buildButton('√', 'sqrt', _ButtonKind.advanced),
              _buildButton('x²', 'square', _ButtonKind.advanced),
            ],
          ),
          SizedBox(height: gap),
          _buildKeypadRow(
            keyHeight: keyHeight,
            gap: gap,
            buttons: [
              _buildButton('7', '7', _ButtonKind.number),
              _buildButton('8', '8', _ButtonKind.number),
              _buildButton('9', '9', _ButtonKind.number),
              _buildButton('×', 'multiply', _ButtonKind.operator),
            ],
          ),
          SizedBox(height: gap),
          _buildKeypadRow(
            keyHeight: keyHeight,
            gap: gap,
            buttons: [
              _buildButton('4', '4', _ButtonKind.number),
              _buildButton('5', '5', _ButtonKind.number),
              _buildButton('6', '6', _ButtonKind.number),
              _buildButton('−', 'subtract', _ButtonKind.operator),
            ],
          ),
          SizedBox(height: gap),
          _buildKeypadRow(
            keyHeight: keyHeight,
            gap: gap,
            buttons: [
              _buildButton('1', '1', _ButtonKind.number),
              _buildButton('2', '2', _ButtonKind.number),
              _buildButton('3', '3', _ButtonKind.number),
              _buildButton('+', 'add', _ButtonKind.operator),
            ],
          ),
          SizedBox(height: gap),
          _buildKeypadRow(
            keyHeight: keyHeight,
            gap: gap,
            spans: const [1, 1, 2],
            buttons: [
              _buildButton('0', '0', _ButtonKind.number),
              _buildButton(',', 'decimal', _ButtonKind.number),
              _buildButton('=', 'equals', _ButtonKind.equals),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow({
    required double keyHeight,
    required double gap,
    required List<Widget> buttons,
    List<int>? spans,
  }) {
    final buttonSpans = spans ?? List<int>.filled(buttons.length, 1);

    return SizedBox(
      height: keyHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = (constraints.maxWidth - gap * 3) / 4;
          final children = <Widget>[];

          for (var index = 0; index < buttons.length; index++) {
            if (index > 0) children.add(SizedBox(width: gap));
            final span = buttonSpans[index];
            children.add(
              SizedBox(
                width: columnWidth * span + gap * (span - 1),
                child: buttons[index],
              ),
            );
          }

          return Row(children: children);
        },
      ),
    );
  }

  Widget _buildButton(String label, String keyName, _ButtonKind kind) {
    return _CalculatorButton(
      key: Key('button_$keyName'),
      label: label,
      kind: kind,
      onPressed: () {
        _keyboardFocusNode.requestFocus();
        _onButtonPressed(label);
      },
    );
  }
}

enum _ButtonKind { number, function, advanced, clear, operator, equals }

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    super.key,
    required this.label,
    required this.kind,
    required this.onPressed,
  });

  final String label;
  final _ButtonKind kind;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(22);
    final isEquals = kind == _ButtonKind.equals;
    final backgroundColor = switch (kind) {
      _ButtonKind.number => _numberButtonColor,
      _ButtonKind.function => const Color(0xFF1E293B),
      _ButtonKind.advanced => const Color(0xFF172554),
      _ButtonKind.clear => const Color(0xFF2A1B2A),
      _ButtonKind.operator => _operatorColor,
      _ButtonKind.equals => Colors.transparent,
    };
    final borderColor = switch (kind) {
      _ButtonKind.number => _numberBorderColor,
      _ButtonKind.function => const Color(0xFF3A475C),
      _ButtonKind.advanced => const Color(0xFF3B82F6),
      _ButtonKind.clear => const Color(0xFF633044),
      _ButtonKind.operator => const Color(0xFF7778F4),
      _ButtonKind.equals => const Color(0xFF67D4FF),
    };
    final textColor = kind == _ButtonKind.clear
        ? const Color(0xFFFF718F)
        : kind == _ButtonKind.function || kind == _ButtonKind.advanced
        ? const Color(0xFFCBD5E1)
        : Colors.white;
    final fontSize = switch (kind) {
      _ButtonKind.clear => 23.0,
      _ButtonKind.equals => 32.0,
      _ButtonKind.operator => 30.0,
      _ButtonKind.advanced => 26.0,
      _ => 28.0,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: isEquals
            ? const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
              )
            : null,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: isEquals ? 12 : 7,
            offset: const Offset(0, 3),
          ),
          if (isEquals)
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
              blurRadius: 15,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: isEquals
                    ? FontWeight.bold
                    : kind == _ButtonKind.number
                    ? FontWeight.w500
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
