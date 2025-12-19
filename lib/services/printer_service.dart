import 'package:flutter/foundation.dart';

class PrinterService {
  // --- Singleton Pattern ---
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() {
    return _instance;
  }

  PrinterService._internal();

  // --- State Management: ValueNotifier ---
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

  void setConnectionStatus(bool isConnected, [dynamic device]) {
    if (isConnectedNotifier.value != isConnected) {
      isConnectedNotifier.value = isConnected;
      print('✅ PRINTER SERVICE: Status changed to $isConnected');
    }
  }

  Future<bool> connectToPrinter(dynamic device) async {

    setConnectionStatus(true, device);
    return true;
  }

  bool isConnected() {
    return isConnectedNotifier.value;
  }
}
