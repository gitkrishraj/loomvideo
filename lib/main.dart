
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:async';
import 'dart:io';

class  LoomVideoApp extends StatefulWidget {
  @override
  _LoomVideoAppState createState() => _LoomVideoAppState();
}

class _LoomVideoAppState extends State<LoomVideoApp> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool isRecording = false;
  Timer? _timer;
  int _recordingDuration = 0;
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(cameras![selectedCameraIndex], ResolutionPreset.high);

      try {
        await _controller!.initialize();
        setState(() {}); 
      } catch (e) {
        print('Error initializing camera: $e');
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration += 1;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _startRecording() async {
    if (_controller != null && !_controller!.value.isRecordingVideo) {
      try {
        await _controller!.startVideoRecording();
        _startTimer();
        setState(() {
          isRecording = true;
        });
      } catch (e) {
        print('Error starting recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_controller != null && _controller!.value.isRecordingVideo) {
      try {
        XFile videoFile = await _controller!.stopVideoRecording();
        _stopTimer();
        setState(() {
          isRecording = false;
          _recordingDuration = 0;
        });

        
        await _saveVideoToGallery(videoFile.path);
      } catch (e) {
        print('Error stopping recording: $e');
      }
    }
  }

  Future<void> _saveVideoToGallery(String filePath) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final newPath = '${directory.path}/$fileName';
      
      // Move the video file to a new path
      final File videoFile = File(filePath);
      final File newVideoFile = await videoFile.copy(newPath);
      
      // Save the video file to the gallery
      final result = await ImageGallerySaver.saveFile(newVideoFile.path);
      print('Video saved to gallery: $result');
    } catch (e) {
      print('Error saving video: $e');
    }
  }

  void _toggleCamera() async {
    if (cameras != null && cameras!.length > 1) {
      setState(() {
        selectedCameraIndex = selectedCameraIndex == 0 ? 1 : 0;
      });
      await _initializeCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loom Video App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_controller!),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _formatDuration(_recordingDuration),
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isRecording)
                    IconButton(
                      icon: Icon(Icons.play_circle_fill, size: 60, color: Colors.green),
                      onPressed: _startRecording,
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.stop_circle, size: 60, color: Colors.red),
                      onPressed: _stopRecording,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(
  theme: ThemeData.dark(),
  home: LoomVideoApp(),
));
