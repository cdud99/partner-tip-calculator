import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';
import 'package:untitled/summary_page.dart';

import '../partner_class.dart';

enum ScreenMode { liveFeed, gallery }

class ScanPage extends StatefulWidget {
  const ScanPage(
      {super.key,
      this.text,
      this.onScreenModeChanged,
      this.initialDirection = CameraLensDirection.back});

  final String? text;
  final Function(ScreenMode mode)? onScreenModeChanged;
  final CameraLensDirection initialDirection;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  // This enum is from a different package, so a new value could be added at
  // any time. The example should keep working if that happens.
  // ignore: dead_code
  return Icons.camera;
}

class _ScanPageState extends State<ScanPage> {
  ScreenMode _mode = ScreenMode.gallery;
  CameraController? _controller;
  int _cameraIndex = -1;
  late Widget body;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isBusy = false;
  List<CameraDescription> _cameras = [];
  List<Partner> partners = [];
  bool firstPage = true;

  var logger = Logger();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _initializeCameraController() async {
    _cameras = await availableCameras();
    _cameraIndex = 0;

    if (_cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = _cameras.indexOf(
        _cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }

    if (_cameraIndex == -1) {
      logger.d('No cameras found');
      return;
    }

    _controller = CameraController(
      _cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // If the controller is updated then update the UI.
    _controller!.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (_controller!.value.hasError) {
        showInSnackBar('Camera error ${_controller!.value.errorDescription}');
      }
    });

    try {
      logger.d('Initializing camera');
      await _controller!.initialize();
      logger.d('Camera initialized');
      _controller?.startImageStream(_processCameraImage);
      logger.d('Started image stream');
      _mode = ScreenMode.liveFeed;
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          // iOS only
          showInSnackBar('Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          // iOS only
          showInSnackBar('Audio access is restricted.');
          break;
        default:
          _showCameraException(e);
      }
    }

    if (mounted) {
      showInSnackBar('Scan the first page of your report');
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    body = Center(child: CircularProgressIndicator());
    _initializeCameraController();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // elevation: 0,
        // title: Text(firstPage ? 'Scan Page' : 'Scan Next Page'),
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: () => Navigator.pop(context), icon: Icon(Icons.clear)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: _switchScreenMode,
              child: kDebugMode
                  ? Icon(
                      _mode == ScreenMode.gallery
                          ? Icons.photo_camera_outlined
                          : Icons.no_photography_outlined,
                    )
                  : null,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTapDown: (details) => _handleTap(details),
        child: _mode == ScreenMode.liveFeed
            ? _liveFeedBody()
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void _logError(String code, String? message) {
    // ignore: avoid_print
    print('Error: $code${message == null ? '' : '\nError Message: $message'}');
  }

  Widget _liveFeedBody() {
    if (_mode != ScreenMode.liveFeed) return Container();
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return Container(
      color: Colors.black,
      child: Transform.scale(
        scale: scale,
        child: Center(
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  void _switchScreenMode() {
    if (_mode == ScreenMode.liveFeed) {
      if (mounted) {
        setState(() {
          _mode = ScreenMode.gallery;
        });
      }
      _stopLiveFeed();
    } else {
      // _mode = ScreenMode.liveFeed;
      _initializeCameraController();
    }
    if (widget.onScreenModeChanged != null) {
      widget.onScreenModeChanged!(_mode);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future _stopLiveFeed() async {
    // await _controller?.stopImageStream();
    _controller?.dispose();
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = _cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    // final planeData = image.planes.map(
    //   (Plane plane) {
    //     return InputImagePlaneMetadata(
    //       bytesPerRow: plane.bytesPerRow,
    //       height: plane.height,
    //       width: plane.width,
    //     );
    //   },
    // ).toList();

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

    processImage(inputImage);
  }

  Future<void> processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;
    final recognizedText = await _textRecognizer.processImage(inputImage);
    int step = 0;
    int partnerZero = partners.length;
    int line = 0;
    bool showReasonForError = true;
    if (!firstPage) showReasonForError = true;
    bool needAnotherPage = true;
    double totalHours = 0.0;
    mainLoop:
    for (var i = 0; i < recognizedText.blocks.length; i++) {
      List<String> chunks = recognizedText.blocks[i].text.split(RegExp(r'\n+'));
      for (var x = 0; x < chunks.length; x++) {
        final previousBlockText = x == 0
            ? recognizedText.blocks[i > 0 ? i - 1 : 0].text.trim().toLowerCase()
            : chunks[x - 1].trim();
        String currentBlockText = chunks[x].trim().toLowerCase();
        if (step != 2) {
          currentBlockText = currentBlockText.replaceAll(' ', '');
        }
        // print(currentBlockText);
        if (step == 0) {
          // Locate start of partners
          if (firstPage &&
              currentBlockText == 'store' &&
              previousBlockText == 'home') {
            step = 1;
            // logger.d('Moving to step 1');
            continue;
          } else if (!firstPage &&
              RegExp(r'^\d{5}$').hasMatch(currentBlockText)) {
            step = 1;
            // logger.d('Moving to step 1');
            final Partner partner = Partner();
            partner.storeNumber = int.parse(currentBlockText);
            partners.add(partner);
            continue;
          } else if (!firstPage && currentBlockText == 'totaltippablehours:') {
            logger.d('Last page\n$currentBlockText');
            needAnotherPage = false;
            step = 4;
            continue;
          }
        } else if (step == 1) {
          // Store number
          if (firstPage && currentBlockText == 'partnername') {
            step = 2;
            // logger.d('Moving to step 2');
            continue;
          } else if (!firstPage &&
              RegExp(r'^[a-z ,]*$').hasMatch(currentBlockText)) {
            step = 2;
            // logger.d('Moving to step 2');
            line = 0;
            partners[partnerZero + line++].name = currentBlockText;
            continue;
          } else if (!RegExp(r'^\d{5}$').hasMatch(currentBlockText)) {
            removePartners(partnerZero);
            if (showReasonForError) logger.d('Step $step: $currentBlockText');
            break mainLoop;
          }
          final Partner partner = Partner();
          partner.storeNumber = int.parse(currentBlockText);
          partners.add(partner);
        } else if (step == 2) {
          // Name
          currentBlockText = currentBlockText.replaceAll('.', ',');
          currentBlockText = currentBlockText.replaceAll('|', 'l');
          if (firstPage && currentBlockText == 'partner number') {
            step = 3;
            // logger.d('Moving to step 3');
            line = 0;
            continue;
          } else if (!firstPage &&
              RegExp(r'^us[\d]{1,8}$').hasMatch(currentBlockText)) {
            step = 3;
            // logger.d('Moving to step 3');
            line = 0;
            partners[partnerZero + line++].numbers = currentBlockText;
            continue;
          } else if (!RegExp(r'^[a-z ,-]*$').hasMatch(currentBlockText) ||
              partnerZero + line >= partners.length) {
            if (showReasonForError) {
              logger.d(
                  'Step $step: $currentBlockText\n$partnerZero $line ${partners.length}');
            }
            removePartners(partnerZero);
            break mainLoop;
          }
          partners[partnerZero + line++].name = currentBlockText;
        } else if (step == 3) {
          // Numbers
          if (firstPage && currentBlockText == 'totaltippable') {
            step = 4;
            // logger.d('Moving to step 4');
            line = 0;
            continue;
          } else if (!firstPage &&
              RegExp(r'^[\d]{1,2}\.[\d]{2}$').hasMatch(currentBlockText)) {
            step = 4;
            // logger.d('Moving to step 4');
            line = 0;
            partners[partnerZero + line++].hours =
                double.parse(currentBlockText);
            continue;
          } else if (currentBlockText == 'totaltippablehours:') {
            logger.d('Last page');
            needAnotherPage = false;
            continue;
          } else if (!RegExp(r'^us[\d]{1,8}$').hasMatch(currentBlockText) ||
              partnerZero + line >= partners.length) {
            removePartners(partnerZero);
            if (showReasonForError) logger.d('Step $step: $currentBlockText');
            break mainLoop;
          }
          partners[partnerZero + line++].numbers = currentBlockText;
        } else if (step == 4) {
          // Hours
          if (partnerZero + line == partners.length) {
            logger.d('Step $step: $currentBlockText');
            if (RegExp(r'^[\d]*\.[\d]{2}$').hasMatch(currentBlockText)) {
              totalHours = double.parse(currentBlockText);
            } else {
              removePartners(partnerZero);
            }
            break mainLoop;
          } else if (currentBlockText == 'hours') {
            continue;
          } else if (!RegExp(r'^[\d]{1,2}\.[\d]{2}$')
              .hasMatch(currentBlockText)) {
            removePartners(partnerZero);
            if (showReasonForError) logger.d('Step $step: $currentBlockText');
            break mainLoop;
          }
          partners[partnerZero + line++].hours = double.parse(currentBlockText);
        }
      }
    }
    if (partners.length > partnerZero || (!firstPage && totalHours != 0)) {
      if (needAnotherPage) {
        showInSnackBar('Scan the next page');
        logger.d('Total Partners ${partners.length}');
        firstPage = false;
      } else {
        double addedHours = 0;
        for (var partner in partners) {
          addedHours += partner.hours;
        }
        if ((totalHours - addedHours).abs() > 0.01) {
          logger.d('Mismatch hours: $addedHours $totalHours');
          firstPage = true;
          partners = [];
          showInSnackBar('Let\'s try again from the first page');
        } else {
          logger.d('Total Partners ${partners.length}');
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            SummaryPage.routeName,
            ModalRoute.withName('/home'),
            arguments: SummaryArguments(partners, 318, totalHours),
          );
          return;
        }
      }
    }
    // if (inputImage.metadata?.size != null &&
    //     inputImage.metadata?.rotation != null) {
    //   final painter = TextRecognizerPainter(recognizedText,
    //       inputImage.metadata!.size, inputImage.metadata!.rotation);
    //   _customPaint = CustomPaint(painter: painter);
    // } else {
    //   _customPaint = null;
    // }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void removePartners(int partnerZero) {
    while (partners.length > partnerZero) {
      partners.removeAt(partners.length - 1);
    }
  }

  void _handleTap(TapDownDetails details) async {
    final Offset globalPosition =
        details.globalPosition; // Get the global coordinates
    final double x = globalPosition.dx;
    final double y = globalPosition.dy;

    final Size screenDimensions = MediaQuery.of(context).size;
    final double screenX = screenDimensions.width;
    final double screenY = screenDimensions.height;

    await _controller!.setFocusPoint(Offset((x / screenX), (y / screenY)));

    // logger.d('$x $y\n$screenX $screenY');
  }
}
