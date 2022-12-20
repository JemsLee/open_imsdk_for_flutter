
import 'dart:async';
import '../utils/event_bus.dart';
import 'MessageBody.dart';
import '../utils/AESEncrypt.dart';
import '../utils/Logger.dart';
import '../utils/TimeUtils.dart';
import 'IMWebsocket.dart';
import 'IMManagerSubject.dart';
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
  late Timer timerPing;
  // late Timer timerCheck;
  // Timer? timerLostMessage;
  // Timer? checkNetWorkStatus;
  IMWebsocket imWebsocket = IMWebsocket();
  bool isFirst = true;
  String pingTime = "";
  bool started = false;

  var subscription;
  String _stateText = "";//用来显示状态
  bool isConnectedNetwork = true;


  ///事件机制
  IMEventBus eventBus = IMEventBus() ;
  ///启动Socket
  ///ping
  ///reconnect
  void start() {
    connectToServer();
  }

  // static const timecheck = Duration(seconds: 7);
  // void checkTimer(){
  //   timerCheck = Timer.periodic(timecheck, (timer) {
  //     if(!timerPing.isActive){
  //       Logger.info("------Resetting timerPing-----");
  //       startPing();
  //     }
  //   });
  //
  // }

  ///ping
  static const timeping = Duration(seconds: 5);
  void startPing(){
    timerPing = Timer.periodic(timeping, (timer) {
      if(imWebsocket.isLogin && started) {
        imWebsocket.sendMessage(createPingString());
      }else{
        if(started){
          Logger.info("------进入重连-----");
          connectToServer();
        }
      }
    });
  }

  // ///每10秒检查是否有发送失败的消息，可以重发
  // static const timeLoop = Duration(seconds: 10);
  // void startResendLostMessage() {
  //   timerLostMessage = Timer.periodic(timeLoop, (timer) {
  //     while(imWebsocket.isLogin && lostMessage.isNotEmpty){
  //       sendMessage(lostMessage.last,0);
  //       lostMessage.removeLast();
  //     }
  //   });
  // }

  /// Check IM Status
  // static const timeCheckNetWork = Duration(seconds: 6);
  // void startcCheckImStatus() {
  //   checkNetWorkStatus = Timer.periodic(timeCheckNetWork, (timer) {
  //     if(!imWebsocket.isLogin){
  //       Logger.info("------进入重连-----");
  //       connectToServer();
  //     }
  //   });
  // }

  ///链接到服务器
  bool isStarting = false;
  void connectToServer(){
    if(!isStarting) {//去重
      isStarting = true;
      Future.delayed(const Duration(seconds: 1), () {
        stop();
        init();
        imWebsocket.connect();
      }).then((onValue) {
        Future.delayed(const Duration(seconds: 2), () {
          imWebsocket.sendMessage(createLoginString());
          startPing();
          // startListenNetWorkStatus();
          // startResendLostMessage();
          // startcCheckImStatus();
          // startPing();
        });
      });
      isStarting = false;
    }
  }

  ///停止Socket
  void stop() {
    try {
      started = false;
      // timerCheck.cancel();
      timerPing.cancel();
      // checkNetWorkStatus?.cancel();
      // timerLostMessage?.cancel();
      imWebsocket.isLogin = false;
      imWebsocket.disconnect();
      // timerLostMessage = null;
      // checkNetWorkStatus = null;
    }catch(e){
      eventBus?.emit("immessage",IMManagerSubject(e.toString(),"ERROR"));
    }
  }

  ///停止Socket
  void release() {
    try {
      started = false;
      // timerCheck.cancel();
      timerPing.cancel();
      // checkNetWorkStatus?.cancel();
      // timerLostMessage?.cancel();
      imWebsocket.isLogin = false;
      imWebsocket.disconnect();
      subscription?.cancel();
      // timerLostMessage = null;
      // checkNetWorkStatus = null;
      subscription = null;
    }catch(e){
      eventBus?.emit("immessage",IMManagerSubject(e.toString(),"ERROR"));
    }
  }

  ///初始化 Parametes
  Future<void> init() async {
    imWebsocket = IMWebsocket();
    imWebsocket.imAddress = imIPAndPort;
    imWebsocket.fromUid = fromUid;
    key = AESEncrypt.createKey(fromUid);
    imWebsocket.eventBus = eventBus;
    imWebsocket.key = key;
    var needacks = needACK.split(",");
    for(int i = 0;i < needacks.length;i++) {
      imWebsocket.ackmap[needacks[i]] = needacks[i];
    }
    started = true;
  }

  // bool isfirst = true;
  // ///监听本机的网络状态
  // void startListenNetWorkStatus(){
  //   if(isfirst) {
  //     isfirst = false;
  //     subscription = Connectivity()
  //         .onConnectivityChanged
  //         .listen((ConnectivityResult result) {
  //       if (result == ConnectivityResult.wifi) {
  //         _stateText = "当前处于wifi网络";
  //         if (!isConnectedNetwork) {
  //           connectToServer();
  //           isConnectedNetwork = true;
  //         }
  //       } else if (result == ConnectivityResult.mobile) {
  //         _stateText = "当前处于数据流量网络";
  //         if (!isConnectedNetwork) {
  //           connectToServer();
  //           isConnectedNetwork = true;
  //         }
  //       } else if (result == ConnectivityResult.none) {
  //         _stateText = "当前无网络连接";
  //         isConnectedNetwork = false;
  //       } else {
  //         _stateText = "处于其他连接";
  //         if (!isConnectedNetwork) {
  //           connectToServer();
  //           isConnectedNetwork = true;
  //         }
  //       }
  //     });
  //   }
  // }




  ///构建登录
  String createLoginString(){
    // deviceId = TimeUtils.getTimeEpoch();
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
  bool sendMessage(String message,int f){
    bool isSend = false;
    if(imWebsocket.isLogin) {
      isSend = imWebsocket.sendMessage(message);
    }else{//发送失败缓存起来
      // if(f == 1) {
      //   lostMessage.add(message);
      // }
      isSend = false;
    }
    return isSend;
  }
}
