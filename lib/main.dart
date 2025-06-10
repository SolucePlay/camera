import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(CameraApp(camera: firstCamera));
}

class CameraApp extends StatelessWidget {
  final CameraDescription camera;

  const CameraApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _lastPhoto;
  bool _flashOn = false;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high,
        enableAudio: false);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final dir = await getTemporaryDirectory();
      final path = join(dir.path, '${DateTime.now()}.png');
      final image = await _controller.takePicture();

      setState(() {
        _lastPhoto = image;
      });
    } catch (e) {
      print(e);
    }
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
      _controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _toggleZoom() {
    setState(() {
      _zoomed = !_zoomed;
      _controller.setZoomLevel(_zoomed ? 2.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          _flashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                        onPressed: _toggleFlash,
                      ),
                      IconButton(
                        icon: Icon(
                          _zoomed ? Icons.zoom_in : Icons.zoom_out,
                          color: Colors.white,
                        ),
                        onPressed: _toggleZoom,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: IconButton(
                    icon: Icon(Icons.camera, size: 40, color: Colors.white),
                    onPressed: _takePicture,
                  ),
                ),
                if (_lastPhoto != null)
                  Positioned(
                    bottom: 100,
                    right: 20,
                    child: Image.file(
                      File(_lastPhoto!.path),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}