import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netease_cloud_music_cookie/event/qr_code_state_event.dart';
import 'package:netease_cloud_music_cookie/global.dart';
import 'package:netease_cloud_music_cookie/network/netease_client.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class LoginWidgetQrCode extends StatefulWidget {
  const LoginWidgetQrCode({super.key});

  @override
  State<LoginWidgetQrCode> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidgetQrCode> {
  var _loginUniKey = "";
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QrCodeWidget(_loginUniKey),
        TextButton(
          child: Text(_loginUniKey == "" ? "获取二维码" : "刷新二维码"),
          onPressed: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("Loading...")));
            NeteaseClient.instance.createLoginToken().then((value) {
              final code = value["code"] as int;
              if (code == 200) {
                setState(() {
                  _loginUniKey = value["unikey"].toString();
                });
              } else {
                throw Exception("code=$code");
              }
            }).catchError((err, stack) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err.toString())));
            });
          },
        )
      ],
    ));
  }
}

class _QrCodeWidget extends StatefulWidget {
  const _QrCodeWidget(this.loginUniKey, {super.key});

  final String loginUniKey;

  @override
  State<_QrCodeWidget> createState() => __QrCodeWidgetState();
}

class __QrCodeWidgetState extends State<_QrCodeWidget> {
  Timer? _timer;
  bool _succeed = false;
  List<Widget> _buildContent() {
    if (widget.loginUniKey == "") {
      return [];
    } else {
      return [
        PrettyQr(
          data: "https://music.163.com/login?codekey=${widget.loginUniKey}",
          roundEdges: true,
        ),
        Text(widget.loginUniKey)
      ];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    _succeed = false;
    if (widget.loginUniKey != "") {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        NeteaseClient.instance
            .getLoginTokenState(widget.loginUniKey)
            .then((response) {
          final body = response.data;
          if (body != null) {
            final bodyMap = body as Map<String, dynamic>;
            final code = bodyMap["code"] as int;
            final desc = bodyMap["message"] as String;
            debugPrint(bodyMap.toString());
            String? cookie;
            if (_succeed) return;
            if (code == 803) {
              // 成功
              cookie = response.headers["Set-Cookie"]!.join("; ");
              _succeed = true;
              timer.cancel();
              _timer = null;
            } else if (code == 800) {
              // 过期
              _succeed = false;
              timer.cancel();
              _timer = null;
            }
            Global.eventBus.fire(
                QrCodeState(state: code, description: desc, cookie: cookie));
          }
        });
      });
    }

    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildContent(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _timer = null;
  }
}
