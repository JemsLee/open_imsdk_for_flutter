import 'dart:convert' as convert;

class MessageBody {

  String eventId = "";//事件ID，参考事件ID文件
  String fromUid = "";//发送者ID  举例：越南  VI100000_源ID
  String token = "";//发送者token
  String channelId = "";//用户的channel

  String toUid = "";//接收者ID，多个以逗号隔开  重点：对于客户端发送过来的消息，不能和groupId并存，两者只能同时出现一个，举例：越南  VI100000_源ID
  String mType = "";//消息类型 ，50直播间，0-系统，1-私聊
  String cTimest = "";//客户端发送时间搓
  String sTimest = "";//服务端接收时间搓
  String dataBody = "";//消息体，可以自由定义，以字符串格式传入{'type':0,1,2,}

  String isGroup = "0";//是否群组 1-群组，0-个人
  String groupId = "";//群组ID ，对于客户端发送过来的消息，不能和toUid并存，两者只能同时出现一个
  String groupName = "";//群组名称

  String pkGroupId = ""; //pk时使用
  String spUid = "";//特殊用户ID
  String isAck = "0";//客户端接收到服务端发送的消息后，返回的状态= 1；dataBody结构 sTimest,sTimest,sTimest,sTimest......

  String isCache = "1";//是否需要存离线 1-需要，0-不需要
  String deviceId = "";//唯一设备id，目前用AFID作为标识，登录时带入
  String oldChannelId = "";//准备离线的channel
  String isRobot = "0";//是否机器人 1-机器人

  String nikeName = "";

  String fbFlag = "";//分包的标记 VI100000

  String toJSON(){
    final map = <String, String>{};
    map["eventId"] = eventId;
    map["fromUid"] = fromUid;
    map["token"] = token;
    map["channelId"] = channelId;

    map["toUid"] = toUid;
    map["mType"] = mType;
    map["cTimest"] = cTimest;
    map["sTimest"] = sTimest;
    map["dataBody"] = dataBody;

    map["isGroup"] = isGroup;
    map["groupId"] = groupId;
    map["groupName"] = groupName;

    map["pkGroupId"] = pkGroupId;
    map["spUid"] = spUid;
    map["isAck"] = isAck;

    map["isCache"] = isCache;
    map["deviceId"] = deviceId;
    map["oldChannelId"] = oldChannelId;
    map["isRobot"] = isRobot;

    map["nikeName"] = nikeName;
    map["fbFlag"] = fbFlag;
    String jsonString = convert.jsonEncode(map);
    return jsonString;
  }


}
