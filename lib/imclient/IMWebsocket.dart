import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert' as convert;

import '../utils/AESEncrypt.dart';
import '../utils/Logger.dart';
import '../utils/TimeUtils.dart';
import 'IMManagerSubject.dart';
import 'MessageBody.dart';



enum StatusEnum { connect, connecting, close, closing }

class IMWebsocket {
  WebSocketChannel? channel;
  StatusEnum isConnect = StatusEnum.close; //默认为未连接
  String imAddress = "";
  String fromUid = "";
  bool isLogin = false;
  String key = "";
  Map<String,String> ackmap = {};


  ///事件机制
  EventBus? eventBus ;

  ///链接服务器
  Future connect() async {
    if (isConnect == StatusEnum.close) {
      isConnect = StatusEnum.connecting;
      channel = IOWebSocketChannel.connect(Uri.parse(imAddress));
      channel?.stream.listen(_onReceive, onDone: () {
        isLogin = false;
        eventBus?.fire(IMManagerSubject("Server closed channel.....","ERROR"));
      }, onError: (error) {
        isLogin = false;
        eventBus?.fire(IMManagerSubject("Channel error.....","ERROR"));
      }, cancelOnError: true);
      isConnect = StatusEnum.connect;
      return true;
    }
  }

  ///关闭链接
  Future disconnect() async {
    if (isConnect == StatusEnum.connect) {
      isConnect = StatusEnum.closing;
      await channel?.sink.close(3000, "客户端主动关闭");
      isConnect = StatusEnum.close;
    }
  }

  ///发送数据给服务器
  bool sendMessage(String text) {
    if (isConnect == StatusEnum.connect) {
      channel?.sink.add(text);
      return true;
    }
    return false;
  }

  ///处理收到的消息
  void _onReceive(message) {

    bool isJsonFormat = false;
    Map<String, dynamic> data = {};
    try {
      data = convert.jsonDecode(message);
      isJsonFormat = true;
    } catch (e) {}

    if(isJsonFormat){
       if(data["resDesc"] == "登录成功"){
         isLogin = true;
         eventBus?.fire(IMManagerSubject(message,"OK"));
       }
    }else{
      String decString = AESEncrypt.aesDecrypted(message,key);
      eventBus?.fire(IMManagerSubject(decString,"OK"));
      // Logger.info("解密后的数据：$decString");
      data = convert.jsonDecode(decString);
      if(ackmap[data["eventId"]] != null){
        sendMessage(createACKString(data["sTimest"]));
      }
    }
  }

  ///构建ACK
  String createACKString(String sTimest) {
    MessageBody messageBody = MessageBody();
    messageBody.eventId = "1000001";
    messageBody.fromUid = fromUid;
    messageBody.isAck = "1";
    messageBody.sTimest = sTimest;
    messageBody.cTimest = TimeUtils.getTimeEpoch();
    messageBody.isCache = "0";
    messageBody.mType = "1";
    String jsonStr = messageBody.toJSON();
    jsonStr = AESEncrypt.aesEncoded(jsonStr,key);
    return jsonStr;
  }
}
