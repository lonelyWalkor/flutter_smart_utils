import 'package:event_bus/event_bus.dart';

/// The global [EventBus] object.
EventBus eventBus = EventBus();

/// Event A.
class BlueToothScaleValueChange {
  String value;

  BlueToothScaleValueChange(this.value);
}



class UserLocationChange {
  Map value;

  UserLocationChange(this.value);
}


class InitiativeLeave {
  bool value;

  InitiativeLeave(this.value);
}



class BluerReceiveData {
  String value;

  BluerReceiveData(this.value);
}

/// 收到极光消息
class JPushReceiveMessage  {
  Map<String, dynamic> value;

  JPushReceiveMessage(this.value);
}
