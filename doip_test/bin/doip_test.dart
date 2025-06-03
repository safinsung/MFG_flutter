import 'dart:io';
import 'dart:typed_data';

Future<void> main() async {
  final address = '192.168.200.1'; // 你的 ECU/車輛 IP
  final port = 13400; // DoIP 埠號

  try {
    final socket = await Socket.connect(address, port);
    print('✅ 已連線至車輛 DoIP check');

    final routingActivationRequest = Uint8List.fromList([
      0x02, 0x10, 0x00, 0x10,   // Payload length: 16 (0x10)
      0x0E, 0x00,               // Source Address (e.g. 0x0E00)
      0x10, 0x01,               // Target Address (e.g. 0x1001)
      0x00, 0x00, 0x00, 0x01,   // Activation Type
      0x00, 0x00, 0x00, 0x00    // Reserved / OEM-specific data
    ]);

    socket.add(routingActivationRequest);
    await socket.flush();
    await Future.delayed(Duration(milliseconds: 200));

    final udsReadDTCRequest = Uint8List.fromList([
      0x02, 0x00, 0x00, 0x08,
      0x0E, 0x00,
      0x10, 0x01,
      0x19, 0x02,
      0xFF
    ]);

    socket.add(udsReadDTCRequest);
    await socket.flush();

    socket.listen((Uint8List data) {
      print('📥 收到資料: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ")}');

      if (data.length > 8) {
        final dtcCount = (data.length - 8) ~/ 4;
        for (int i = 0; i < dtcCount; i++) {
          final offset = 8 + i * 4;
          final dtcBytes = data.sublist(offset, offset + 3);
          final dtcCode = dtcBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
          print('🚨 DTC 故障碼: $dtcCode');
        }
      }
    });
  } catch (e) {
    print('❌ 錯誤: $e');
  }
}
