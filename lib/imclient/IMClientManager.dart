
import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../utils/event_bus.dart';
import 'MessageBody.dart';
import '../utils/AESEncrypt.dart';
import '../utils/Logger.dart';
import '../utils/TimeUtils.dart';
import 'IMWebsocket.dart';
import 'IMManagerSubject.dart';


///IMClientManager.dart
///Jem.Lee
///2022.7.3
///Version 1.0.0

class IMClientManager with WidgetsBindingObserver{ //with WidgetsBindingObserver

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
  String platform = "";

  List<String> lostMessage = [];


  String key = "";
  Timer? timerPing;
  Timer? checkNetWorkStatus;
  IMWebsocket imWebsocket = IMWebsocket();
  String pingTime = "";
  bool started = false;

  bool isFirst = true;



  ///事件机制
  IMEventBus eventBus = IMEventBus() ;
  ///启动Socket
  ///ping
  ///reconnect
  void start() {

    if(isFirst) {
      isFirst = false;
      _cancelTimer();
      //////////////保活机制////////////////////////
      //监听生命周期
      WidgetsBinding.instance.addObserver(this);
      //定时器
      _initIMCheckTimer();
    }

    connectToServer();
  }

  ///ping
  static const timeping = Duration(seconds: 7);
  void startPing(){
    timerPing = Timer.periodic(timeping, (timer) {
      if(imWebsocket.isLogin && started) {
        imWebsocket.sendMessage(createPingString());
      }
    });
  }

  /// Check IM Status
  static const timeCheckNetWork = Duration(seconds: 3);
  void startcCheckImStatus() {
    checkNetWorkStatus = Timer.periodic(timeCheckNetWork, (timer) {
      if(started) {
        if (!imWebsocket.isLogin) {
          Logger.info("------Manager进入重连-----");
          connectToServer();
        }
      }
    });
  }

  ///链接到服务器
  bool isStarting = false;
  void connectToServer(){
    if(!isStarting) {//去重
      isStarting = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        stop();
        init();
        imWebsocket.connect();
      }).then((onValue) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          imWebsocket.loginToServer(createLoginString());
          startPing();
          isStarting = false;
          startcCheckImStatus();
        });
      });

    }
  }

  ///停止Socket
  void stop() {
    try {
      started = false;
      timerPing?.cancel();
      checkNetWorkStatus?.cancel();
      imWebsocket.isLogin = false;
      imWebsocket.started = started;
      imWebsocket.disconnect();
      checkNetWorkStatus = null;
      timerPing = null;
    }catch(e){
      eventBus?.emit("immessage",IMManagerSubject(e.toString(),"ERROR"));
    }
  }

  ///初始化 Parametes
  Future<void> init() async {
    imWebsocket = IMWebsocket();
    imWebsocket.imAddress = imIPAndPort;
    imWebsocket.fromUid = fromUid;
    imWebsocket.started = started;
    key = AESEncrypt.createKey(fromUid);
    imWebsocket.eventBus = eventBus;
    imWebsocket.key = key;

    var needacks = needACK.split(",");
    for(int i = 0;i < needacks.length;i++) {
      imWebsocket.ackmap[needacks[i]] = needacks[i];
    }
    started = true;

  }

  ///构建登录
  String createLoginString(){
    // deviceId = TimeUtils.getTimeEpoch();
    MessageBody messageBody = MessageBody();
    messageBody.eventId = "1000000";
    messageBody.fromUid = fromUid;
    messageBody.token = token;
    messageBody.deviceId = deviceId;
    messageBody.dataBody = platform;
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
  bool sendMessage(String message,int f){
    return imWebsocket.sendMessage(message);
  }



////////////////////////////////////////IM保活机制开始//////////////////////////////////////////////////////
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("--" + state.toString());
    switch (state) {
      case AppLifecycleState.inactive: // 应用程序可见,不可操作。
        print("应用程序可见,不可操作。");
        break;
      case AppLifecycleState.resumed: // 应用程序可见,可操作, 前台
        print("应用程序可见,可操作, 前台。");
        _initIMCheckTimer(); //创建并开启定时器
        break;
      case AppLifecycleState.paused: // 应用程序不可见，不可操作, 后台
        print("应用程序不可见，不可操作, 后台。");
        _cancelTimer(); //取消并销毁定时器
        break;
      case AppLifecycleState.detached: //  虽然还在运行，但已经没有任何存在的界面。
        break;
    }
  }

  ///dispose
  @override
  void dispose() {
    //销毁监听生命周期
    WidgetsBinding.instance.removeObserver(this);
    //取消定时器
    _cancelTimer();
  }

  //定时器
  late Timer? _imCheckTimer;

  ///定时器 - 1分钟
  void _initIMCheckTimer() {
    _imCheckTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if(!imWebsocket.isLogin && started){
        print("重新初始化IM.........");
        init();
        start();
      }
    });
  }

  ///取消定时器
  void _cancelTimer() {
    try {
      _imCheckTimer?.cancel();
      _imCheckTimer = null;
    }catch(e){print(e.toString());}
  }

////////////////////////////////////////IM保活机制结束//////////////////////////////////////////////////////


}
