import 'package:flutter/material.dart';
import 'package:netease_cloud_music_cookie/ui/cookie_widget.dart';
import 'package:netease_cloud_music_cookie/ui/login_widget_qrcode.dart';

class MainPage extends StatelessWidget {
  const MainPage(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const _MainPageBody(),
    );
  }
}

class _MainPageBody extends StatelessWidget {
  const _MainPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: const [
          Expanded(flex: 3, child: LoginWidgetQrCode()),
          Expanded(flex: 7, child: CookieWidget())
        ],
      ),
    );
  }
}
