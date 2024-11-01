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
      title: 'Image Picker and Crop',
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
  Rect? _cropRect;
  ui.Image? _croppedImage;
  double _cornerSize = 20; // Size of the corners for resizing

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _cropRect = Rect.fromLTWH(100, 100, 200, 200); // Default crop rectangle
      });
    }
  }

  // Function to crop the image manually
  Future<void> _cropImage() async {
    if (_imageFile == null ||
        _cropRect == null ||
        _cropRect!.width <= 0 ||
        _cropRect!.height <= 0) return;

    try {
      // Load the image from the file
      final data = await _imageFile!.readAsBytes();
      final image = await decodeImageFromList(data);

      // Create a recorder to draw the cropped image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the image with the defined crop rectangle
      canvas.drawImageRect(
        image,
        _cropRect!,
        Rect.fromLTWH(0, 0, _cropRect!.width, _cropRect!.height),
        Paint(),
      );

      // End recording and create the cropped image
      _croppedImage = await recorder.endRecording().toImage(
            _cropRect!.width.toInt(),
            _cropRect!.height.toInt(),
          );

      // Refresh UI after cropping
      setState(() {});
    } catch (e) {
      print("Error cropping image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Picker and Crop'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null)
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    // Update the crop rectangle position
                    _cropRect = _cropRect!
                        .translate(details.delta.dx, details.delta.dy);
                  });
                },
                child: Stack(
                  children: [
                    Image.file(_imageFile!),
                    if (_cropRect != null &&
                        _cropRect!.isFinite) // Ensure rect is finite
                      Positioned.fromRect(
                        rect: _cropRect!,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.red, width: 2), // Red border
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Text('No image selected.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cropImage,
              child: Text('Crop Image'),
            ),
            if (_croppedImage != null) // Display the cropped image
              ClipRect(
                child: CustomPaint(
                  size: Size(_cropRect!.width,
                      _cropRect!.height), // Match crop rectangle size
                  painter: ImagePainter(_croppedImage!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build resizable corners
  Widget _buildResizableCorner(Offset offset) {
    return Positioned(
      left: offset.dx - _cornerSize / 2,
      top: offset.dy - _cornerSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Update the crop rectangle size based on the corner being dragged
            if (offset == Offset(0, 0)) {
              // Top-left corner
              _cropRect = Rect.fromLTRB(
                _cropRect!.right + details.delta.dx,
                _cropRect!.bottom + details.delta.dy,
                _cropRect!.right,
                _cropRect!.bottom,
              );
            } else if (offset == Offset(_cropRect!.width, 0)) {
              // Top-right corner
              _cropRect = Rect.fromLTRB(
                _cropRect!.left,
                _cropRect!.top + details.delta.dy,
                _cropRect!.left + details.delta.dx,
                _cropRect!.top,
              );
            } else if (offset == Offset(_cropRect!.width, _cropRect!.height)) {
              // Bottom-right corner
              _cropRect = Rect.fromLTRB(
                _cropRect!.left,
                _cropRect!.top,
                _cropRect!.left + details.delta.dx,
                _cropRect!.top + details.delta.dy,
              );
            } else {
              // Bottom-left corner
              _cropRect = Rect.fromLTRB(
                _cropRect!.left + details.delta.dx,
                _cropRect!.top,
                _cropRect!.left,
                _cropRect!.top + details.delta.dy,
              );
            }
          });
        },
        child: Container(
          width: _cornerSize,
          height: _cornerSize,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// CustomPainter to draw the cropped image
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
