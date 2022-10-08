import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as Encrypt;
import 'package:encrypt/encrypt.dart';

class AESEncrypt{


  ///使用md5加密
  static String createKey(String fromUid) {
    Uint8List content = new Utf8Encoder().convert(fromUid);
    Digest digest = md5.convert(content);
    return digest.toString();
  }

  static const String _iv = '';
  ///aes加密函数
  static String aesEncoded(String content,String secKey) {

    //加密key
    final key = Encrypt.Key.fromUtf8(secKey);
    //偏移量
    final iv = Encrypt.IV.fromUtf8(_iv);
    //ecb
    final encrypter = Encrypt.Encrypter(
        Encrypt.AES(key, mode: Encrypt.AESMode.ecb, padding: 'PKCS7'));
    //加密
    final encrypted = encrypter.encrypt(content, iv: iv);
    return encrypted.base64;

  }

  /// 解密函数
  static String aesDecrypted(String data,String secKey){
    //加密key
    final key = Encrypt.Key.fromUtf8(secKey);
    //偏移量
    final iv = Encrypt.IV.fromUtf8(_iv);
    //设置ecb模式
    final encrypter = Encrypt.Encrypter(
        Encrypt.AES(key, mode: Encrypt.AESMode.ecb, padding: 'PKCS7'));
    return encrypter.decrypt(Encrypted.fromBase64(data), iv: iv);

  }
}