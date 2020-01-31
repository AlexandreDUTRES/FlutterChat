import 'package:event_bus/event_bus.dart';

enum EventFlag {
  socketError,
  socketConnected,
  socketUserLogged,
  socketNewMessage,
  socketUserJoined,
  socketUserLeft,
  socketTyping,
  socketStopTyping
}

class Event {
  static Event _instance;

  static EventBus bus = EventBus();

  static Event get instance {
    if (_instance == null) _instance = new Event();
    return _instance;
  }

  EventBus getBus(){
    return bus;
  }
}

class GlobalEvent{
  EventFlag flag;
  Map value;

  GlobalEvent(this.flag, this.value);
}