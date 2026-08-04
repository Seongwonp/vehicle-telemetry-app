import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:telemetrix/core/auth/token_storage.dart';

typedef RequestHandler = FutureOr<ResponseBody> Function(
    RequestOptions options);

class CallbackHttpClientAdapter implements HttpClientAdapter {
  final RequestHandler handler;

  CallbackHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? body, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class MemoryTokenStore implements TokenStore {
  String? accessToken;
  String? refreshToken;
  String? username;
  int clearCount = 0;

  MemoryTokenStore({this.accessToken, this.refreshToken, this.username});

  @override
  Future<void> save(String accessToken, String refreshToken,
      [String? username]) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    if (username != null) this.username = username;
  }

  @override
  Future<String?> getToken() async => accessToken;
  @override
  Future<String?> getRefreshToken() async => refreshToken;
  @override
  Future<String?> getUsername() async => username;
  @override
  Future<bool> hasToken() async => accessToken != null;

  @override
  Future<void> clear() async {
    clearCount++;
    accessToken = null;
    refreshToken = null;
    username = null;
  }
}
