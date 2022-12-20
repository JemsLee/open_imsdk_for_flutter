import 'dart:async';

import 'package:flutter/material.dart';
import 'package:itimsdkflutter/imclient/IMClientManager.dart';
import 'package:itimsdkflutter/imclient/IMManagerSubject.dart';
import 'package:itimsdkflutter/imclient/MessageBody.dart';
import 'package:itimsdkflutter/utils/AESEncrypt.dart';
import 'package:itimsdkflutter/utils/Logger.dart';
import 'package:itimsdkflutter/utils/TimeUtils.dart';
import 'package:itimsdkflutter/utils/event_bus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  void _incrementCounter() {
    setState(() {


    });

  }

  var imclient = IMClientManager();
  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  late IMEventCallback _imEventBusCallBack;

  @override
  void initState() {
    super.initState();

    //由于是单例，所以必须先判断是否已经初始化了
    imclient.imIPAndPort = "wss://im.btliveroom.live";
    imclient.fromUid = "1001_30099";
    imclient.token = "123";
    imclient.deviceId = "1649303524433-44426425";
    imclient.needACK = "1000001,5000004,8000000";
    imclient.init();

    connectToImServer();
    // doLoopTest();
    // doStopTest();
    setIMListenEvent();
    // var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    // final InitializationSettings initializationSettings = InitializationSettings(android: android);
    // flutterLocalNotificationsPlugin.initialize(initializationSettings,);

  }

  void connectToImServer() async{
    if (!imclient.isLogin) {
        imclient.start();
    }
  }

  void setIMListenEvent(){
    _imEventBusCallBack = (dynamic) {
      if(dynamic is IMManagerSubject){
        updateView(dynamic.message);
        Logger.info("界面接收到的消息:${dynamic.message}");
        // Logger.info("界面接收到消息类型:${dynamic.mType}");
        if(dynamic.message.contains("登录成功")){
          sendJoinGroupExample();
        }
      }
    };
    ///监听广播
    imclient.eventBus.on("immessage", _imEventBusCallBack);
  }

  ///每10秒检查是否有发送失败的消息，可以重发
  Timer? timerLoop;
  static const timeLoop = Duration(seconds: 14 );
  void doLoopTest() {
    timerLoop = Timer.periodic(timeLoop, (timer) {
      connectToImServer();
    });
  }

  ///每10秒检查是否有发送失败的消息，可以重发
  Timer? timerStop;
  static const timeStop = Duration(seconds: 11);
  void doStopTest() {
    timerStop = Timer.periodic(timeStop, (timer) {
      imclient.stop();
      updateView("客户端测试断开");
    });
  }
  ///更新界面
  String receiveMessage = "";
  void updateView(String message){
    setState(() {
      receiveMessage = message;
    });
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    super.setState(fn);


  }

  ///测试发送消息
  void sendJoinGroupExample() {
    MessageBody messageBody = new MessageBody();
    messageBody.eventId = "5000001";
    messageBody.fromUid = imclient.fromUid;
    messageBody.groupId = "1001_314780_1665306248";
    messageBody.isGroup = "1";
    messageBody.cTimest = TimeUtils.getTimeEpoch();
    messageBody.dataBody = "";
    messageBody.mType = "50";
    messageBody.isCache = "0";
    String jsonStr = messageBody.toJSON();
    jsonStr = AESEncrypt.aesEncoded(jsonStr,imclient.key);
    bool rs = imclient.sendMessage(jsonStr,1);
    if(!rs){
      Logger.info("手动进入重连");
      imclient.stop();
      connectToImServer();
    }
  }

  ///测试发送消息
  void sendMessageToGroupExample() {
    MessageBody messageBody = new MessageBody();
    messageBody.eventId = "5000004";
    messageBody.fromUid = imclient.fromUid;
    messageBody.groupId = "1001_314780_1665306248";
    messageBody.isGroup = "1";
    messageBody.cTimest = TimeUtils.getTimeEpoch();
    messageBody.dataBody = "消息内容";
    messageBody.mType = "50";
    messageBody.isCache = "0";
    String jsonStr = messageBody.toJSON();
    jsonStr = AESEncrypt.aesEncoded(jsonStr,imclient.key);
    bool rs = imclient.sendMessage(jsonStr,1);
    if(!rs){
      Logger.info("手动进入重连");
      imclient.stop();
      connectToImServer();
    }
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
      //   // Center is a layout widget. It takes a single child and positions it
      //   // in the middle of the parent.
        child: Column(
      //     // Column is also a layout widget. It takes a list of children and
      //     // arranges them vertically. By default, it sizes itself to fit its
      //     // children horizontally, and tries to be as tall as its parent.
      //     //
      //     // Invoke "debug painting" (press "p" in the console, choose the
      //     // "Toggle Debug Paint" action from the Flutter Inspector in Android
      //     // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
      //     // to see the wireframe for each widget.
      //     //
      //     // Column has various properties to control how it sizes itself and
      //     // how it positions its children. Here we use mainAxisAlignment to
      //     // center the children vertically; the main axis here is the vertical
      //     // axis because Columns are vertical (the cross axis would be
      //     // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              receiveMessage
            ),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

