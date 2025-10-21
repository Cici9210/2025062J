// 心臟壓感互動系統測試檔案
//
// 功能: 測試應用程式的基本UI元素和行為

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heartbeat_app/main.dart';

void main() {
  testWidgets('應用啟動時顯示登入畫面', (WidgetTester tester) async {
    // 構建應用並觸發一個幀
    await tester.pumpWidget(const MyApp());

    // 驗證登入畫面是否顯示
    expect(find.text('心臟壓感互動系統'), findsOneWidget);
    expect(find.byType(TextField), findsAtLeastNWidgets(2)); // 至少有2個文字輸入框
    expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1)); // 至少有1個按鈕
  });

  testWidgets('登入欄位驗證', (WidgetTester tester) async {
    // 構建應用並觸發一個幀
    await tester.pumpWidget(const MyApp());

    // 尋找並驗證登入按鈕存在
    final loginButton = find.byType(ElevatedButton).first;
    expect(loginButton, findsOneWidget);

    // 點擊登入按鈕而不輸入資料，應該顯示驗證錯誤
    await tester.tap(loginButton);
    await tester.pump();

    // 驗證畫面仍然是登入畫面
    expect(find.text('心臟壓感互動系統'), findsOneWidget);
  });
}
