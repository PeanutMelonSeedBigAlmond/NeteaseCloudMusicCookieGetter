import 'package:netease_cloud_music_cookie/network/netease_client.dart';

void main() async {
  final client = NeteaseClient.instance;

  final data = await client.createLoginToken();
  print(data);
}
