import 'package:flutter/material.dart';

// MaterialApp의 home:은 이미 push된 라우트 위에서는 상태가 바뀌어도 자동으로
// 반영되지 않는다(로그인/로그아웃 화면들이 pushAndRemoveUntil로 우회하는 이유와 동일).
// 리프레시 토큰 만료 같은 "화면 밖에서" 일어나는 강제 로그아웃도 같은 방식으로
// 스택을 리셋해야 하는데, 그 트리거가 위젯 트리 밖(AuthNotifier)에 있어서
// BuildContext가 없다 — 그래서 전역 키로 Navigator에 직접 접근한다.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
