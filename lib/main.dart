import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Lens Style Crop',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _imageFile;
  ui.Image? _uiImage;
  Rect? _cropRect;
  ui.Image? _croppedImage;
  double _cornerSize = 20;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      final data = await _imageFile!.readAsBytes();
      _uiImage = await decodeImageFromList(data);

      setState(() {
        _cropRect = null;
        _croppedImage = null; // Reset cropped image when new image is picked
      });
    }
  }

  void _initializeCropRect(TapDownDetails details) {
    final tapPosition = details.localPosition;
    setState(() {
      _cropRect = Rect.fromLTWH(
        tapPosition.dx - 50,
        tapPosition.dy - 50,
        100,
        100,
      );
    });
  }

  void _adjustCropRect(Offset corner, DragUpdateDetails details) {
    setState(() {
      double newLeft = _cropRect!.left;
      double newTop = _cropRect!.top;
      double newRight = _cropRect!.right;
      double newBottom = _cropRect!.bottom;

      if (corner == Offset(_cropRect!.left, _cropRect!.top)) {
        newLeft += details.delta.dx;
        newTop += details.delta.dy;
      } else if (corner == Offset(_cropRect!.right, _cropRect!.top)) {
        newRight += details.delta.dx;
        newTop += details.delta.dy;
      } else if (corner == Offset(_cropRect!.left, _cropRect!.bottom)) {
        newLeft += details.delta.dx;
        newBottom += details.delta.dy;
      } else if (corner == Offset(_cropRect!.right, _cropRect!.bottom)) {
        newRight += details.delta.dx;
        newBottom += details.delta.dy;
      }

      _cropRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
    });
  }

  Future<void> _cropImage() async {
    if (_imageFile == null || _cropRect == null || _uiImage == null) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      _uiImage!,
      _cropRect!,
      Rect.fromLTWH(0, 0, _cropRect!.width, _cropRect!.height),
      Paint(),
    );

    final croppedImage = await recorder.endRecording().toImage(
          _cropRect!.width.toInt(),
          _cropRect!.height.toInt(),
        );

    setState(() {
      _croppedImage = croppedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Lens Style Crop')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null)
              GestureDetector(
                onTapDown: _initializeCropRect,
                child: Stack(
                  children: [
                    Image.file(_imageFile!),
                    if (_cropRect != null)
                      Positioned.fill(
                        child: Stack(
                          children: [
                            Container(color: Colors.black54),
                            Positioned.fromRect(
                              rect: _cropRect!,
                              child: Container(
                                color: Colors.transparent,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      _cropRect = _cropRect!.translate(
                                          details.delta.dx, details.delta.dy);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildCorner(
                                Offset(_cropRect!.left, _cropRect!.top)),
                            _buildCorner(
                                Offset(_cropRect!.right, _cropRect!.top)),
                            _buildCorner(
                                Offset(_cropRect!.left, _cropRect!.bottom)),
                            _buildCorner(
                                Offset(_cropRect!.right, _cropRect!.bottom)),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            else
              Text('No image selected. Tap to pick one!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            if (_cropRect != null)
              ElevatedButton(
                onPressed: _cropImage,
                child: Text('Crop Image'),
              ),
            SizedBox(height: 20),
            if (_croppedImage != null)
              Container(
                padding: EdgeInsets.all(10),
                color: Colors.grey[200],
                child: CustomPaint(
                  size: Size(_cropRect!.width, _cropRect!.height),
                  painter: ImagePainter(_croppedImage!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Offset corner) {
    return Positioned(
      left: corner.dx - _cornerSize / 2,
      top: corner.dy - _cornerSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) => _adjustCropRect(corner, details),
        child: Container(
          width: _cornerSize,
          height: _cornerSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1),
          ),
        ),
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
