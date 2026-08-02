import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const AvatarCropScreen({super.key, required this.imageBytes});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _boundaryKey = GlobalKey();
  final _transformController = TransformationController();
  bool _saving = false;

  static const double _cropSize = 280;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final rawBytes =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rawBytes == null) {
        throw Exception('Görsel işlenemedi');
      }

      final rgbaImage = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: rawBytes.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      final jpg = img.encodeJpg(rgbaImage, quality: 85);
      final base64Str = base64Encode(jpg);

      if (!mounted) return;
      Navigator.of(context).pop(base64Str);
    } catch (e) {
      debugPrint('EcoChef avatar kırpma hatası: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Fotoğraf işlenirken bir sorun oluştu, tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Avatarı Ayarla'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _confirm,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Kaydet',
                    style:
                        TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Fotoğrafı çerçeve içine sığdırmak için kaydır ve yakınlaştır',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    key: _boundaryKey,
                    child: SizedBox(
                      width: _cropSize,
                      height: _cropSize,
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1,
                        maxScale: 4,
                        child: Image.memory(
                          widget.imageBytes,
                          width: _cropSize,
                          height: _cropSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: ClipPath(
                      clipper: _CircleHoleClipper(),
                      child: Container(
                        width: _cropSize,
                        height: _cropSize,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      width: _cropSize,
                      height: _cropSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CircleHoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circle = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ));
    return Path.combine(PathOperation.difference, path, circle);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
