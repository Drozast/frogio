import 'dart:async';

class SessionTimeoutService {
  static const int _timeoutMinutes = 30;
  Timer? _timer;
  DateTime? _lastActivityTime;
  
  Function()? onSessionTimeout;
  
  void startTimer() {
    _timer?.cancel();
    _lastActivityTime = DateTime.now();
    
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkTimeout();
    });
  }
  
  void updateLastActivityTime() {
    _lastActivityTime = DateTime.now();
  }
  
  void checkTimeout() {
    if (_lastActivityTime == null) return;
    
    final currentTime = DateTime.now();
    final difference = currentTime.difference(_lastActivityTime!);
    
    if (difference.inMinutes >= _timeoutMinutes) {
      _timer?.cancel();
      onSessionTimeout?.call();
    }
  }
  
  void stopTimer() {
    _timer?.cancel();
    _lastActivityTime = null;
  }
}