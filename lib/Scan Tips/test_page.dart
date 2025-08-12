import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  bool initialized = false;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  Future initCamera() async {
    print('Initializing Camera');
    _cameras = await availableCameras();
    print('Got available cameras: ${_cameras.length}');
    int cameraIndex = 0;

    if (_cameras.any(
      (element) =>
          element.lensDirection == CameraLensDirection.back &&
          element.sensorOrientation == 90,
    )) {
      cameraIndex = _cameras.indexOf(
        _cameras.firstWhere((element) =>
            element.lensDirection == CameraLensDirection.back &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.back) {
          cameraIndex = i;
          break;
        }
      }
    }
    print('Camera index is: $cameraIndex');
    _controller = CameraController(
      _cameras[cameraIndex], // Use the first available camera
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    print('Built camera controller');

    try {
      await _controller.initialize();
      await Future.wait(<Future<Object?>>[
        // The exposure mode is currently not supported on the web.
        ...true
            ? <Future<Object?>>[
                _controller.getMinExposureOffset().then(
                    (double value) => _minAvailableExposureOffset = value),
                _controller
                    .getMaxExposureOffset()
                    .then((double value) => _maxAvailableExposureOffset = value)
              ]
            : <Future<Object?>>[],
        _controller
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        _controller
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          print('You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          print('Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          // iOS only
          print('Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          print('You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          print('Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          // iOS only
          print('Audio access is restricted.');
          break;
        default:
          print(e);
      }
    }
  }

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // if (!initialized) initCamera();
    return Scaffold(
      // body: initialized
      //     ? CameraPreview(_controller)
      //     : Center(child: CircularProgressIndicator()),
      body: Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(onPressed: () => initCamera()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
