import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:th1_nguyenxuantruong_2324801030073/main.dart';

Future<void> _press(WidgetTester tester, String keyName) async {
  await tester.tap(find.byKey(Key('button_$keyName')));
  await tester.pump();
}

Future<void> _pressKeyboardKey(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  String? character,
  PhysicalKeyboardKey? physicalKey,
}) async {
  await tester.sendKeyEvent(
    key,
    character: character,
    physicalKey: physicalKey,
  );
  await tester.pump();
}

String _displayValue(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('calculator_display'))).data!;
}

String _expressionValue(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const Key('calculator_expression')))
      .data!;
}

void main() {
  testWidgets('hiển thị đúng giao diện và dữ liệu khởi tạo', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(_displayValue(tester), '0');
    expect(_expressionValue(tester), isEmpty);
    expect(
      find.text('MSSV: 2324801030073 • NGUYỄN XUÂN TRƯỜNG'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('button_equals')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('thực hiện đúng bốn phép tính cơ bản', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _press(tester, '2');
    await _press(tester, 'add');
    await _press(tester, '3');
    await _press(tester, 'equals');
    expect(_displayValue(tester), '5');

    await _press(tester, 'ac');
    await _press(tester, '1');
    await _press(tester, '0');
    await _press(tester, 'subtract');
    await _press(tester, '6');
    await _press(tester, 'equals');
    expect(_displayValue(tester), '4');

    await _press(tester, 'ac');
    await _press(tester, '5');
    await _press(tester, 'multiply');
    await _press(tester, '8');
    await _press(tester, 'equals');
    expect(_displayValue(tester), '40');

    await _press(tester, 'ac');
    await _press(tester, '1');
    await _press(tester, '0');
    await _press(tester, 'divide');
    await _press(tester, '4');
    await _press(tester, 'equals');
    expect(_displayValue(tester), '2,5');
  });

  testWidgets('hỗ trợ dấu phẩy thập phân và định dạng kết quả', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _press(tester, '2');
    await _press(tester, 'decimal');
    await _press(tester, '5');
    await _press(tester, 'add');
    await _press(tester, '1');
    await _press(tester, 'decimal');
    await _press(tester, '5');
    await _press(tester, 'equals');
    expect(_displayValue(tester), '4');

    await _press(tester, 'ac');
    await _press(tester, '0');
    await _press(tester, 'decimal');
    await _press(tester, '5');
    await _press(tester, 'multiply');
    await _press(tester, '4');
    await _press(tester, 'equals');
    expect(_displayValue(tester), '2');

    await _press(tester, 'ac');
    await _press(tester, '1');
    await _press(tester, 'decimal');
    await _press(tester, '5');
    await _press(tester, 'decimal');
    expect(_displayValue(tester), '1,5');
  });

  testWidgets('phần trăm và đổi dấu hoạt động trên số hiện tại', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await _press(tester, '5');
    await _press(tester, '0');
    await _press(tester, 'percent');
    expect(_displayValue(tester), '0,5');

    await _press(tester, 'ac');
    await _press(tester, '2');
    await _press(tester, '5');
    await _press(tester, 'percent');
    expect(_displayValue(tester), '0,25');

    await _press(tester, 'ac');
    await _press(tester, '2');
    await _press(tester, '0');
    await _press(tester, '0');
    await _press(tester, 'percent');
    expect(_displayValue(tester), '2');

    await _press(tester, 'ac');
    await _press(tester, '5');
    await _press(tester, 'sign');
    expect(_displayValue(tester), '-5');
    await _press(tester, 'sign');
    expect(_displayValue(tester), '5');

    await _press(tester, 'ac');
    await _press(tester, '1');
    await _press(tester, '2');
    await _press(tester, 'decimal');
    await _press(tester, '5');
    await _press(tester, 'sign');
    expect(_displayValue(tester), '-12,5');
  });

  testWidgets('làm tròn sai số floating point hợp lý', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _press(tester, '0');
    await _press(tester, 'decimal');
    await _press(tester, '1');
    await _press(tester, 'add');
    await _press(tester, '0');
    await _press(tester, 'decimal');
    await _press(tester, '2');
    await _press(tester, 'equals');
    expect(_displayValue(tester), '0,3');
  });

  testWidgets('xử lý phép chia cho không và khôi phục an toàn', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _press(tester, '9');
    await _press(tester, 'divide');
    await _press(tester, '0');
    await _press(tester, 'equals');
    expect(_displayValue(tester), 'Cannot divide by zero');
    expect(_expressionValue(tester), '9 ÷ 0 =');

    final errorText = tester.widget<Text>(
      find.byKey(const Key('calculator_display')),
    );
    expect(errorText.style?.color, Colors.white);
    expect(errorText.style?.fontWeight, FontWeight.bold);
    expect(errorText.style!.fontSize, lessThan(56));
    expect(tester.takeException(), isNull);

    await _press(tester, '7');
    expect(_displayValue(tester), '7');
    expect(_expressionValue(tester), isEmpty);

    await _press(tester, 'divide');
    await _press(tester, '0');
    await _press(tester, 'equals');
    expect(_displayValue(tester), 'Cannot divide by zero');

    await _press(tester, 'ac');
    expect(_displayValue(tester), '0');
    expect(_expressionValue(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('xử lý đúng trạng thái sau kết quả và toán tử liên tiếp', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await _press(tester, '5');
    await _press(tester, 'add');
    await _press(tester, 'multiply');
    expect(_expressionValue(tester), '5 ×');

    await _press(tester, 'ac');
    await _press(tester, '2');
    await _press(tester, 'add');
    await _press(tester, '3');
    await _press(tester, 'equals');
    await _press(tester, '7');
    expect(_displayValue(tester), '7');
    expect(_expressionValue(tester), isEmpty);

    await _press(tester, 'ac');
    await _press(tester, '2');
    await _press(tester, 'add');
    await _press(tester, '3');
    await _press(tester, 'equals');
    await _press(tester, 'add');
    await _press(tester, '4');
    await _press(tester, 'equals');
    expect(_displayValue(tester), '9');
  });

  testWidgets('nhập số âm và phép tính bằng bàn phím vật lý', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await _pressKeyboardKey(tester, LogicalKeyboardKey.minus, character: '-');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit5, character: '5');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.equal, character: '+');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit2, character: '2');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.enter);
    expect(_displayValue(tester), '-3');

    await _pressKeyboardKey(tester, LogicalKeyboardKey.escape);
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit5, character: '5');
    await _pressKeyboardKey(
      tester,
      LogicalKeyboardKey.asterisk,
      character: '*',
      physicalKey: PhysicalKeyboardKey.digit8,
    );
    await _pressKeyboardKey(tester, LogicalKeyboardKey.minus, character: '-');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit2, character: '2');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.equal, character: '=');
    expect(_displayValue(tester), '-10');

    await _pressKeyboardKey(tester, LogicalKeyboardKey.escape);
    await _pressKeyboardKey(tester, LogicalKeyboardKey.minus, character: '-');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit4, character: '4');
    await _pressKeyboardKey(
      tester,
      LogicalKeyboardKey.asterisk,
      character: '*',
      physicalKey: PhysicalKeyboardKey.digit8,
    );
    await _pressKeyboardKey(tester, LogicalKeyboardKey.minus, character: '-');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit3, character: '3');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.enter);
    expect(_displayValue(tester), '12');

    await _pressKeyboardKey(tester, LogicalKeyboardKey.escape);
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit8, character: '8');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.slash, character: '/');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit2, character: '2');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.enter);
    expect(_displayValue(tester), '4');

    await _pressKeyboardKey(tester, LogicalKeyboardKey.escape);
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit1, character: '1');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit2, character: '2');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.backspace);
    await _pressKeyboardKey(tester, LogicalKeyboardKey.period, character: '.');
    await _pressKeyboardKey(tester, LogicalKeyboardKey.digit5, character: '5');
    expect(_displayValue(tester), '1,5');
    expect(tester.takeException(), isNull);
  });

  testWidgets('căn bậc hai xử lý số hợp lệ và số âm an toàn', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _press(tester, '9');
    await _press(tester, 'sqrt');
    expect(_displayValue(tester), '3');

    await _press(tester, 'ac');
    await _press(tester, '2');
    await _press(tester, 'sqrt');
    expect(_displayValue(tester), startsWith('1,41421356'));

    await _press(tester, 'ac');
    await _press(tester, '4');
    await _press(tester, 'sign');
    await _press(tester, 'sqrt');
    expect(_displayValue(tester), 'Invalid input');
    expect(_expressionValue(tester), '√-4 =');

    await _press(tester, '7');
    expect(_displayValue(tester), '7');
    expect(_expressionValue(tester), isEmpty);

    await _press(tester, 'sign');
    await _press(tester, 'sqrt');
    expect(_displayValue(tester), 'Invalid input');
    await _press(tester, 'ac');
    expect(_displayValue(tester), '0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('bình phương số nguyên âm và số thập phân', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _press(tester, '5');
    await _press(tester, 'square');
    expect(_displayValue(tester), '25');

    await _press(tester, 'ac');
    await _press(tester, '3');
    await _press(tester, 'sign');
    await _press(tester, 'square');
    expect(_displayValue(tester), '9');

    await _press(tester, 'ac');
    await _press(tester, '2');
    await _press(tester, 'decimal');
    await _press(tester, '5');
    await _press(tester, 'square');
    expect(_displayValue(tester), '6,25');
    expect(tester.takeException(), isNull);
  });

  testWidgets('không overflow trên Android, Chrome và Windows', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const viewportSizes = [
      Size(320, 568),
      Size(1024, 568),
      Size(1280, 480),
      Size(1280, 720),
    ];

    for (final viewportSize in viewportSizes) {
      tester.view.physicalSize = viewportSize;
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.byKey(const Key('button_equals')), findsOneWidget);
      expect(find.byKey(const Key('button_sqrt')), findsOneWidget);
      expect(find.byKey(const Key('button_square')), findsOneWidget);

      await _press(tester, '5');
      await _press(tester, 'divide');
      await _press(tester, '0');
      await _press(tester, 'equals');

      expect(_displayValue(tester), 'Cannot divide by zero');
      expect(
        tester.getBottomRight(find.byKey(const Key('button_equals'))).dy,
        lessThanOrEqualTo(viewportSize.height),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Viewport $viewportSize không được có RenderFlex overflow',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
