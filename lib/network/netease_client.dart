import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:netease_cloud_music_cookie/util/crypto.dart';

class NeteaseClient {
  static NeteaseClient? _instance;
  static NeteaseClient get instance => _getInstance();
  static NeteaseClient _getInstance() {
    _instance ??= NeteaseClient._();
    return _instance!;
  }

  NeteaseClient._();

  final _dio = Dio()
    ..httpClientAdapter = (IOHttpClientAdapter(createHttpClient: () {
      final client = HttpClient();
      // client.findProxy = ((url) => "PROXY 127.0.0.1:8888");
      // client.badCertificateCallback = (cert, host, port) => true;
      return client;
    }))
    ..transformer = (BackgroundTransformer()..jsonDecodeCallback = parseJson);

  static Map<String, dynamic> _parseAndDecode(String response) {
    return jsonDecode(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> parseJson(String text) =>
      compute(_parseAndDecode, text);

  static Future<Map<String,dynamic>> _getResponseBody(Future<Response<dynamic>> response) async {
    return (await response).data!;
  }

  Future<Response<dynamic>> _doPostRequest(String url,
      Map<String, dynamic> data, Map<String, String> headers) async {
    final response = await _dio.post(url,
        data: data,
        options: Options(
            headers: headers, contentType: Headers.formUrlEncodedContentType));

    return response;
  }

  Future<Response<dynamic>> _neteaseRequest(
      String url, String crypto, Map<String, dynamic> data, String cookie,
      {Map<String, String>? options}) async {
    final headers = <String, String>{};
    final cookies = <String, String>{};
    if (url.contains("music.163.com")) {
      headers["Referer"] = "https://music.163.com";
    }

    final reqData = data;
    switch (crypto) {
      case "weapi":
        final csrfToken = cookies["_csrf"] ?? "";
        headers["csrf_token"] = csrfToken;
        final data1 = Crypto.weapi(reqData);
        final url1 = url.replaceAll(RegExp("\\w*api"), "weapi");
        return _doPostRequest(url1, data1, headers);
      case "eapi":
        final csrfToken = cookies["__csrf_token"] ?? "";
        final header = <String, String?>{
          "osver": cookies["osver"],
          "deviceId": cookies["deviceId"],
          "appver": cookies["appver"] ?? "8.7.01",
          "versioncode": cookies["versioncode"] ?? "140",
          "mobilename": cookies["mobilename"],
          "buildver": cookies["buildver"] ??
              DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10),
          "resolution": cookies["resolution"] ?? "1920x1080",
          "__csrf": csrfToken,
          "os": cookies["os"] ?? "android",
          "channel": cookies["channel"],
          "requestId":
              "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}"
                  .padLeft(4, '0'),
          "MUSIC_U": cookies["MUSIC_U"],
          "MUSIC_A": cookies["MUSIC_A"]
        };
        final sb = StringBuffer();
        header.forEach((key, value) {
          sb.write(
              "${Uri.encodeComponent(key)}=${Uri.encodeComponent(value ?? 'null')}; ");
        });
        headers["Cookie"] = sb.toString();

        final _data = Crypto.eapi(data, url);
        final _url = url.replaceAll(RegExp("\\wapi"), "wapi");
        return _doPostRequest(_url, _data, headers);
      default:
        final newData = {};
        data.forEach((key, value) {
          newData[key] = value.toString();
        });
        return _doPostRequest(url, data, headers);
    }
  }

  Future<Map<String, dynamic>> createLoginToken() async {
    return _getResponseBody(_neteaseRequest("https://music.163.com/weapi/login/qrcode/unikey",
        "weapi", {"type": 1}, ""));
  }

  Future<Response<dynamic>> getLoginTokenState(String key) async {
    return await _neteaseRequest(
        "https://music.163.com/weapi/login/qrcode/client/login",
        "weapi",
        {
          "key": key,
          "type": 1,
        },
        "");
  }
}
