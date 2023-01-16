
import '../imclient/MessageBody.dart';
import 'dart:convert' as convert;

class JSONUtils{

  static String toJSONFromMessageBody(MessageBody messageBody){
    final map = <String, String>{};
    map["eventId"] = messageBody.eventId;
    map["fromUid"] = messageBody.fromUid;
    map["token"] = messageBody.token;
    map["channelId"] = messageBody.channelId;

    map["toUid"] = messageBody.toUid;
    map["mType"] = messageBody.mType;
    map["cTimest"] = messageBody.cTimest;
    map["sTimest"] = messageBody.sTimest;
    map["dataBody"] = messageBody.dataBody;

    map["isGroup"] = messageBody.isGroup;
    map["groupId"] = messageBody.groupId;
    map["groupName"] = messageBody.groupName;

    map["pkGroupId"] = messageBody.pkGroupId;
    map["spUid"] = messageBody.spUid;
    map["isAck"] = messageBody.isAck;

    map["isCache"] = messageBody.isCache;
    map["deviceId"] = messageBody.deviceId;
    map["oldChannelId"] = messageBody.oldChannelId;
    map["isRoot"] = messageBody.isRoot;

    map["fbFlag"] = messageBody.fbFlag;

    String jsonString = convert.jsonEncode(map);
    return jsonString;
  }

}