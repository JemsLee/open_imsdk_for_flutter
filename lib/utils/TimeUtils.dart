

class TimeUtils{

  static String getNowTime(){
    var date = new DateTime.now();
    String timestamp = "${date.year.toString()}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
    return timestamp;
  }


  static String getTimeEpoch(){
    var timenumber = DateTime.now().microsecondsSinceEpoch;//时间
    return "$timenumber";
  }

}