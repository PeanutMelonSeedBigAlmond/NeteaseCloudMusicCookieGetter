import 'package:flutter/material.dart';
import 'package:netease_cloud_music_cookie/event/qr_code_state_event.dart';
import 'package:netease_cloud_music_cookie/global.dart';

class CookieWidget extends StatefulWidget {
  const CookieWidget({super.key});

  @override
  State<CookieWidget> createState() => _CookieWidgetState();
}

class _CookieWidgetState extends State<CookieWidget> {
  String? _cookie;
  String? _desc;
  @override
  void initState() {
    super.initState();
    Global.eventBus.on<QrCodeState>().listen((event) {
      setState(() {
        _cookie = event.cookie;
        _desc = event.description;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SelectableText(_cookie == null
          ? _desc == null
              ? ""
              : _desc!
          : _cookie!),
    );
  }
}
