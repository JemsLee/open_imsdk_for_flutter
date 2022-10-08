import 'package:flutterimsdk/utils/TimeUtils.dart';

class Logger{

  static void info(String desc){
    print("INFO :${TimeUtils.getNowTime()}:$desc");
  }

  static void error(String desc){
    print("ERROR :${TimeUtils.getNowTime()}:$desc");
  }
}