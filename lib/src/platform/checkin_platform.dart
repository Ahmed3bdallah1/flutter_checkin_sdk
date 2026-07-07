import 'checkin_method_channel.dart';
import 'checkin_platform_interface.dart';

bool _isRegistered = false;

/// Registers the default method channel implementation.
void ensureCheckinPlatformRegistered() {
  if (_isRegistered) {
    return;
  }
  CheckinPlatform.instance = MethodChannelCheckinPlatform();
  _isRegistered = true;
}

// Register before any repository reads [CheckinPlatform.instance].
final bool _checkinPlatformBootstrapped = () {
  ensureCheckinPlatformRegistered();
  return true;
}();
 