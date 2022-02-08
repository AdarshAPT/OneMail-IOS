import 'package:f_logs/f_logs.dart';

void logToDevice(
  String className,
  String funcName,
  String text,
  StackTrace? stackTrace,
) {
  FLog.logThis(
    className: className,
    methodName: funcName,
    text: text,
    type: LogLevel.SEVERE,
    stacktrace: stackTrace,
    dataLogType: DataLogType.DEVICE.toString(),
  );
}
