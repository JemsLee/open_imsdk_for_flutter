//订阅者回调签名
typedef void IMEventCallback(dynamic);
class IMEventBus {
  //私有构造函数
  IMEventBus._internal();

  //保存单例
  static final IMEventBus _singleton =  IMEventBus._internal();

  //工厂构造函数
  factory IMEventBus()=> _singleton;

  //保存事件订阅者队列，key:事件名(id)，value: 对应事件的订阅者队列
  final _eMap =  <Object, List<IMEventCallback>?>{};

  //添加订阅者
  void on(eventName, IMEventCallback f) {
    if (eventName == null) return;
    _eMap[eventName] ??=  <IMEventCallback>[];
    _eMap[eventName]?.add(f);
  }

  //移除订阅者
  void off(eventName, [IMEventCallback? f]) {
    var list = _eMap[eventName];
    if (eventName == null || list == null) return;
    if (f == null) {
      _eMap[eventName] = null;
    } else {
      list.remove(f);
    }
  }

  //触发事件，事件触发后该事件所有订阅者会被调用
  void emit(eventName, [arg]) {
    var list = _eMap[eventName];
    if (list == null) return;
    int len = list.length - 1;
    //反向遍历，防止订阅者在回调中移除自身带来的下标错位
    for (var i = len; i > -1; --i) {
      list[i](arg);
    }
  }
}

