import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:hex/hex.dart';
import 'package:netease_cloud_music_cookie/util/encrypt_ext.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/md5.dart';
import 'package:pointycastle/export.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';

class Crypto {
  static const _iv = "0102030405060708";
  static const _presetKey = "0CoJUm6Qyw8W8jud";
  static const _publicKey = """-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgtQn2JZ34ZC28NWYpAUd98iZ37BUrX/
aKzmFbt7clFSs6sXqHauqKWqdtLkF2KexO40H1YTX8z2lSgBBOAxLsvaklV8k4cBFK9snQ
XE9/DDaFt6Rr7iVZMldczhC0JNgTz+SHXT6CBHuX3e9SdB1Ua44oncaTWz7OBGLbCiK45w
IDAQAB
-----END PUBLIC KEY-----""";

  static const _eapiKey = "e82ckenh8dichen8";
  static const _base62 =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  static const _rpcScKey = "7ada0f7ccadbe165e6e7fbe01113f4df";
  static const _alpgabets = "0123456789abcdef";

  static Uint8List _rsa(Uint8List buffer, String publicKey) {
    final publicKey = RsaKeyHelper().parsePublicKeyFromPem(_publicKey);
    final rsa = Encrypter(RSAExt(publicKey: publicKey, privateKey: null));
    return rsa.encryptBytes(buffer).bytes;
  }

  static Uint8List _aes(Uint8List buffer, AESMode mode, String padding,
      Uint8List key, Uint8List iv) {
    final aes = Encrypter(AES(Key(key), mode: mode, padding: padding));

    return aes.encryptBytes(buffer, iv: IV(iv)).bytes;
  }

  static Uint8List _randomBytes(int length) {
    final random = Random();
    final res = Uint8List(length);
    for (int i = 0; i < length; i++) {
      res[i] = random.nextInt(255);
    }
    return res;
  }

  static String _hexStr(Uint8List data) {
    return const HexEncoder().convert(data);
  }

  static Map<String, String> weapi(Map<String, dynamic> data) {
    const encoder = Utf8Encoder();
    final jsonText = json.encode(data);
    final secretKey = Uint8List.fromList(
        _randomBytes(16).map((e) => _base62.codeUnitAt(e % 62)).toList());

    final params = base64Encode(_aes(
        encoder.convert(base64Encode(_aes(
            encoder.convert(jsonText),
            AESMode.cbc,
            "PKCS7",
            encoder.convert(_presetKey),
            encoder.convert(_iv)))),
        AESMode.cbc,
        "PKCS7",
        secretKey,
        encoder.convert(_iv)));
    final encSecKey = _hexStr(
        _rsa(Uint8List.fromList(secretKey.reversed.toList()), _publicKey));
    return {"params": params, "encSecKey": encSecKey};
  }

  static Map<String, String> eapi(Map<String, dynamic> data, String url) {
    final text = json.encode(data);
    final message = "nobody${url}use${text}md5forencrypt";
    const encoder = Utf8Encoder();
    final digest = _hexStr(MD5Digest().process(encoder.convert(message)));
    final data1 = "$url-36cd479b6b5-$text-36cd479b6b5-$digest";

    return {
      "params": _hexStr(_aes(encoder.convert(data1), AESMode.ecb,
              "PKCS5Padding", encoder.convert(_eapiKey), Uint8List(0)))
          .toLowerCase()
    };
  }
}
