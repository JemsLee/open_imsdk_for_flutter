import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert' as convert;

import '../utils/FlutterImSdk.dart'
    if (dart.library.io) '../utils/FlutterImSdk.dart'
    if (dart.library.html) '../utils/WebImSdk.dart' as platform;
import '../utils/AESEncrypt.dart';
import '../utils/TimeUtils.dart';
import '../utils/event_bus.dart';
import 'IMManagerSubject.dart';
import 'MessageBody.dart';

enum StatusEnum { connect, connecting, close, closing }

class IMWebsocket {
  late WebSocketChannel channel;
  StatusEnum isConnect = StatusEnum.close; //默认为未连接
  String imAddress = "";
  String fromUid = "";
  bool isLogin = false;
  String key = "";
  bool started = false;
  Map<String, String> ackmap = {};

  ///事件机制
  IMEventBus? eventBus;

  ///链接服务器
  Future connect() async {
    if (isConnect == StatusEnum.close) {
      channel = platform.FlutterImSdk().getChannel(imAddress);
      channel.stream.listen((event) {
        isConnect = StatusEnum.connect;
        _onReceive(event);
      }, //监听服务器消息
          onError: (error) {
        isLogin = false;
        print("onError---${error.toString()}");
        eventBus?.emit("immessage", IMManagerSubject(error.toString(), "ERROR"));
      }, //连接错误时调用
          onDone: () {
        isLogin = false;
        print("onDone.................");
      }, //关闭时调用
          cancelOnError: true //设置错误时取消订阅
      );

      return true;
    }
  }

  ///关闭链接
  Future disconnect() async {
    try {
      isConnect = StatusEnum.closing;
      started = false;
      await channel?.sink.close(3000, "客户端主动关闭");
      isConnect = StatusEnum.close;
    }catch(e){}
  }

  ///发送数据给服务器
  bool sendMessage(String text) {
    if (isLogin) {
      channel?.sink.add(text);
      return true;
    }
    return false;
  }

  ///登录
  bool loginToServer(String text) {
    try {
      channel?.sink.add(text);
    }catch(e){print(e.toString());}
    return true;
  }

  ///处理收到的消息
  void _onReceive(message) {
    bool isJSONFormat = false;
    Map<String, dynamic> data = {};
    try {
      data = convert.jsonDecode(message);
      isJSONFormat = true;
    } catch (_) {}
    if (isJSONFormat) {
      if (data["resDesc"] == "登录成功") {
        isLogin = true;
      } else {
        isLogin = false;
      }
      eventBus?.emit("immessage", IMManagerSubject(message, "OK"));
    } else {
      String decString = AESEncrypt.aesDecrypted(message, key);
      eventBus?.emit("immessage", IMManagerSubject(decString, "OK"));
      data = convert.jsonDecode(decString);
      if (data["eventId"] == "3000001") {
        isLogin = false;
        disconnect();
      }
      if (ackmap[data["eventId"]] != null) {
        sendMessage(createACKString(data["sTimest"]));
      }
    }
  }

  ///构建ACK
  String createACKString(String sTimest) {
    MessageBody messageBody = MessageBody();
    messageBody.eventId = "1000002";
    messageBody.fromUid = fromUid;
    messageBody.isAck = "1";
    messageBody.sTimest = sTimest;
    messageBody.cTimest = TimeUtils.getTimeEpoch();
    messageBody.isCache = "0";
    messageBody.mType = "1";
    String jsonStr = messageBody.toJSON();
    jsonStr = AESEncrypt.aesEncoded(jsonStr, key);
    return jsonStr;
  }
}
