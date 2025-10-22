import 'package:screen_time/screen_time.dart';

Future<bool> requestScreenTimePermission() async {
  final screenTime = ScreenTime();
  final permissionStatus = await screenTime.requestPermission();

  if (permissionStatus == true) {
    return true;
  } else {
    return false;
  }
}
