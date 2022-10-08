
import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutterimsdk/imclient/MessageBody.dart';
import '../utils/AESEncrypt.dart';
import '../utils/Logger.dart';
import '../utils/TimeUtils.dart';
import 'IMWebsocket.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

///IMClientManager.dart
///Jem.Lee
///2022.7.3
///Version 1.0.0

class IMClientManager {

  static final IMClientManager _singletonPattern = IMClientManager._internal();

  ///工厂构造函数
  factory IMClientManager() {
    return _singletonPattern;
  }

  ///构造函数私有化，防止被误创建
  IMClientManager._internal();

  ///im parameters
  String imIPAndPort = "";
  String fromUid = "";
  String token = "";
  String deviceId = "";
  String needACK = "";
  bool isLogin = false;

  List<String> lostMessage = [];


  String key = "";
  Timer? timerStart;
  Timer? timerLostMessage;
  Timer? checkNetWorkStatus;
  IMWebsocket imWebsocket = IMWebsocket();
  bool isFirst = true;
  String pingTime = "";

  var subscription;
  String _stateText = "";//用来显示状态
  bool isConnectedNetwork = true;


  ///事件机制
  EventBus eventBus = EventBus();
  ///启动Socket
  ///ping
  ///reconnect
  static const timeout = Duration(seconds: 5);
  void start() {
    timerStart = Timer.periodic(timeout, (timer) {
      if(!imWebsocket.isLogin) {//Connect && Login
        Logger.info("imWebsocket.channel.closeCode==${imWebsocket.channel?.closeCode}");
        if("${imWebsocket.channel?.closeCode}" != "null"){
          connectToServer();
          Logger.info("Client do reconnect.");
        }else{
          imWebsocket.sendMessage(createLoginString());
        }
      }else{//doPing

        bool sendRs =  imWebsocket.sendMessage(createPingString());

      }
    });
    listenNetWork();
    startLoopDoLostMessage();
    startcheckNetWorkStatus();
  }

  ///每10秒检查是否有发送失败的消息，可以重发
  static const timeLo0p = Duration(seconds: 10);
  void startLoopDoLostMessage() {
    timerLostMessage = Timer.periodic(timeLo0p, (timer) {
      while(imWebsocket.isLogin && lostMessage.isNotEmpty){
        sendMessage(lostMessage.last,0);
        lostMessage.removeLast();
      }
    });
  }

  ///每10秒检查是否有发送失败的消息，可以重发
  static const timeCheckNetWork = Duration(seconds: 3);
  void startcheckNetWorkStatus() {
    checkNetWorkStatus = Timer.periodic(timeCheckNetWork, (timer) {
      if(!imWebsocket.isLogin){
        Logger.info("Client do startcheckNetWorkStatus.");
        connectToServer();
      }
    });
  }



  ///链接到服务器
  void connectToServer(){
    imWebsocket = IMWebsocket();
    Future.delayed(const Duration(seconds: 1), (){
      init();
    }).then((onValue){
      imWebsocket.sendMessage(createLoginString());
    });
  }

  ///初始化
  Future<void> init() async {
    imWebsocket.imAddress = imIPAndPort;
    imWebsocket.fromUid = fromUid;
    key = AESEncrypt.createKey(fromUid);
    imWebsocket.eventBus = eventBus;
    imWebsocket.key = key;
    var needacks = needACK.split(",");
    for(int i = 0;i < needacks.length;i++) {
      imWebsocket.ackmap[needacks[i]] = needacks[i];
    }
    await imWebsocket.connect();

  }

  ///监听本机的网络状态
  void listenNetWork(){
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.wifi) {
        _stateText = "当前处于wifi网络";
        if(!isConnectedNetwork){
          connectToServer();
          isConnectedNetwork = true;
        }
      } else if (result == ConnectivityResult.mobile) {
        _stateText = "当前处于数据流量网络";
        if(!isConnectedNetwork){
          connectToServer();
          isConnectedNetwork = true;
        }
      } else if (result == ConnectivityResult.none) {
        _stateText = "当前无网络连接";
        isConnectedNetwork = false;
      } else {
        _stateText = "处于其他连接";
        if(!isConnectedNetwork){
          connectToServer();
          isConnectedNetwork = true;
        }
      }
      Logger.info(_stateText);
    });
  }

  ///停止Socket
  void stop() {
    timerLostMessage?.cancel();
    timerStart?.cancel();
    checkNetWorkStatus?.cancel();
    imWebsocket.disconnect();
    subscription.cancel();
  }


  ///构建登录
  String createLoginString(){
    MessageBody messageBody = MessageBody();
    messageBody.eventId = "1000000";
    messageBody.fromUid = fromUid;
    messageBody.token = token;
    messageBody.deviceId = deviceId;
    messageBody.cTimest = TimeUtils.getTimeEpoch();
    String jsonStr = messageBody.toJSON();
    return jsonStr;
  }

  ///构建Ping
  String createPingString() {
    MessageBody messageBody = MessageBody();
    messageBody.eventId = "9000000";
    messageBody.fromUid = fromUid;
    messageBody.token = token;
    messageBody.deviceId = deviceId;
    messageBody.cTimest = TimeUtils.getTimeEpoch();
    pingTime = messageBody.cTimest;
    String jsonStr = messageBody.toJSON();
    jsonStr = AESEncrypt.aesEncoded(jsonStr,key);
    return jsonStr;
  }

  ///发送消息 f == 0,不需要进入循环，直接丢弃
  void sendMessage(String message,int f){
    if(imWebsocket.isLogin) {
      imWebsocket.sendMessage(message);
    }else{//发送失败缓存起来
      if(f == 1) {
        lostMessage.add(message);
      }
    }
  }
}
