import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

class QrDualScreenTab extends StatefulWidget {
  const QrDualScreenTab({Key? key}) : super(key: key);

  @override
  State<QrDualScreenTab> createState() => _QrDualScreenTabState();
}

class _QrDualScreenTabState extends State<QrDualScreenTab> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Uint8List? _qrImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQrImage();
  }

  Future<void> _loadQrImage() async {
    setState(() => _isLoading = true);
    final base64Str = await _storage.read(key: 'qr_image_base64');
    if (base64Str != null && base64Str.isNotEmpty) {
      setState(() {
        _qrImageBytes = base64Decode(base64Str);
      });
    } else {
      setState(() {
        _qrImageBytes = null;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64Str = base64Encode(bytes);
      await _storage.write(key: 'qr_image_base64', value: base64Str);
      setState(() {
        _qrImageBytes = bytes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR image updated!')),
      );
    }
  }

  Future<void> _clearImage() async {
    await _storage.delete(key: 'qr_image_base64');
    setState(() {
      _qrImageBytes = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR image cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ຕັ້ງຄ່າ QR ຮ້ານ',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : _qrImageBytes != null
                    ? Image.memory(_qrImageBytes!, width: 200, height: 200)
                    : const Icon(Icons.qr_code, size: 120, color: Colors.grey),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload),
              label: const Text('ປ່ຽນ QR ໃຫມ່'),
            ),
            const SizedBox(height: 12),
            if (_qrImageBytes != null)
              OutlinedButton.icon(
                onPressed: _clearImage,
                icon: const Icon(Icons.delete),
                label: const Text('ລົບ QR'),
              ),
          ],
        ),
      ),
    );
  }
}
