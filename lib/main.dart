import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignDetectionScreen(cameras: cameras),
    );
  }
}

class SignDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const SignDetectionScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _SignDetectionScreenState createState() => _SignDetectionScreenState();
}

class _SignDetectionScreenState extends State<SignDetectionScreen> {
  late CameraController _controller;
  bool isDetecting = false;
  String detectedSign = "No sign detected";
  Timer? _timer;
  CameraDescription? selectedCamera;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectExternalCamera();
  }

  Future<void> _selectExternalCamera() async {
    // Try to find external camera
    for (var camera in widget.cameras) {
      if (camera.lensDirection == CameraLensDirection.external) {
        selectedCamera = camera;
        break;
      }
    }
    
    // If no external camera found, use the first available camera
    selectedCamera ??= widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      selectedCamera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {});
        _startImageStream();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _startImageStream() {
    const duration = Duration(milliseconds: 1000); // Adjust as needed
    _timer = Timer.periodic(duration, (timer) async {
      if (!_controller.value.isInitialized) return;
      
      final image = await _controller.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      _processImage(base64Image);
    });
  }

  Future<void> _processImage(String base64Image) async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          detectedSign = "Sign: ${result['action']} (${(result['confidence'] * 100).toStringAsFixed(2)}%)";
        });
      }
    } catch (e) {
      setState(() {
        detectedSign = "Error: Cannot connect to server";
      });
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Add a camera switching button to the UI
  Widget _buildCameraSwitchButton() {
    return IconButton(
      icon: const Icon(Icons.switch_camera),
      onPressed: () async {
        int currentIndex = widget.cameras.indexOf(selectedCamera!);
        int nextIndex = (currentIndex + 1) % widget.cameras.length;
        selectedCamera = widget.cameras[nextIndex];
        
        // Dispose current controller
        await _controller.dispose();
        
        // Initialize with new camera
        await _initializeCamera();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Language Detection'),
        actions: [_buildCameraSwitchButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              detectedSign,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
