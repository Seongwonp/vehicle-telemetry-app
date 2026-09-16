import 'package:stomp_dart_client/stomp_dart_client.dart';

/// 네트워크 없이 STOMP 연결·수신·끊김을 흉내 낸다.
/// `dashboard_websocket_test`와 화면 스냅샷이 같이 쓴다.
class FakeStompClient extends StompClient {
  FakeStompClient(StompConfig config) : super(config: config);

  bool activated = false;
  int deactivateCount = 0;
  StompFrameCallback? messageCallback;

  @override
  void activate() => activated = true;

  @override
  void deactivate() {
    deactivateCount++;
    activated = false;
  }

  @override
  StompUnsubscribe subscribe({
    required String destination,
    required StompFrameCallback callback,
    Map<String, String>? headers,
  }) {
    messageCallback = callback;
    return ({Map<String, String>? unsubscribeHeaders}) {};
  }

  Future<void> connect() async {
    await config.beforeConnect();
    config.onConnect(StompFrame(command: 'CONNECTED'));
  }

  void emit(String body) =>
      messageCallback?.call(StompFrame(command: 'MESSAGE', body: body));

  void fail() => config.onWebSocketError(StateError('socket failed'));
  void disconnect() => config.onWebSocketDone();
}
