import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/prediction_response.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final ApiService _apiService = ApiService();
  String _prediction = 'No prediction yet';
  double _confidence = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() {});
      _startImageStream();
    }
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) async {
      if (_isProcessing) return;

      _isProcessing = true;
      try {
        // Convert YUV420 to JPEG
        final bytes = await _processImageBytes(image);
        
        // Send to API
        final prediction = await _apiService.predictSign(bytes);
        
        setState(() {
          _prediction = prediction.action;
          _confidence = prediction.confidence;
        });
      } catch (e) {
        print('Error processing image: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<Uint8List> _processImageBytes(CameraImage image) async {
    // Convert CameraImage to bytes
    // Note: This is a simplified version. You'll need to implement proper
    // image format conversion based on your camera output format
    return Uint8List.fromList([]);  // Implement conversion logic here
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Prediction: $_prediction',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
