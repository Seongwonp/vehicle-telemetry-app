import 'package:flutter/material.dart';

// home:은 이미 push된 라우트 위에서 바뀌지 않아 강제 로그아웃 때 스택을 직접 리셋해야 한다.
// 트리거(AuthNotifier)에 BuildContext가 없어 전역 키를 쓴다.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
