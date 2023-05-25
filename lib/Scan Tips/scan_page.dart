import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';
import 'package:untitled/summary_page.dart';
import 'package:untitled/test_painter.dart';

import '../partner_class.dart';

enum ScreenMode { liveFeed, gallery }

class ScanPage extends StatefulWidget {
  const ScanPage(
      {Key? key,
      this.text,
      this.onScreenModeChanged,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String? text;
  final Function(ScreenMode mode)? onScreenModeChanged;
  final CameraLensDirection initialDirection;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  ScreenMode _mode = ScreenMode.liveFeed;
  CameraController? _controller;
  int _cameraIndex = -1;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  bool _changingCameraLens = false;
  List<CameraDescription> cameras = [];
  Widget? body;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isBusy = false;
  CustomPaint? _customPaint;
  List<Partner> partners = [];
  bool firstPage = true;

  var logger = Logger();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(firstPage ? 'Scan Page' : 'Scan Next Page'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: _switchScreenMode,
              child: Icon(
                _mode == ScreenMode.liveFeed
                    ? Icons.photo_library_outlined
                    : (Platform.isIOS
                        ? Icons.camera_alt_outlined
                        : Icons.camera),
              ),
            ),
          ),
        ],
      ),
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget? _floatingActionButton() {
    if (_mode == ScreenMode.gallery) return null;
    if (cameras.length == 1) return null;
    return SizedBox(
        height: 70.0,
        width: 70.0,
        child: FloatingActionButton(
          onPressed: _switchLiveCamera,
          child: Icon(
            Platform.isIOS
                ? Icons.flip_camera_ios_outlined
                : Icons.flip_camera_android_outlined,
            size: 40,
          ),
        ));
  }

  Widget _body() {
    Future<bool> main() async {
      cameras = await availableCameras();

      if (cameras.any(
        (element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90,
      )) {
        _cameraIndex = cameras.indexOf(
          cameras.firstWhere((element) =>
              element.lensDirection == widget.initialDirection &&
              element.sensorOrientation == 90),
        );
      } else {
        for (var i = 0; i < cameras.length; i++) {
          if (cameras[i].lensDirection == widget.initialDirection) {
            _cameraIndex = i;
            break;
          }
        }
      }

      if (_cameraIndex != -1) {
        await _startLiveFeed();
      }

      if (_mode == ScreenMode.liveFeed) {
        body = _liveFeedBody();
      } else {
        body = Container();
      }
      return true;
    }

    return body == null
        ? FutureBuilder(
            future: main(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  snapshot.data == true) {
                return const Center(child: CircularProgressIndicator());
              }
              return Container();
            })
        : _liveFeedBody();
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
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? const Center(
                      child: Text('Changing camera lens'),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          if (_customPaint != null) _customPaint!,
          // Positioned(
          //   bottom: 100,
          //   left: 50,
          //   right: 50,
          //   child: Slider(
          //     value: zoomLevel,
          //     min: minZoomLevel,
          //     max: maxZoomLevel,
          //     onChanged: (newSliderValue) {
          //       setState(() {
          //         zoomLevel = newSliderValue;
          //         _controller!.setZoomLevel(zoomLevel);
          //       });
          //     },
          //     divisions: (maxZoomLevel - 1).toInt() < 1
          //         ? null
          //         : (maxZoomLevel - 1).toInt(),
          //   ),
          // )
        ],
      ),
    );
  }

  // Future _getImage(ImageSource source) async {
  //   setState(() {
  //     _image = null;
  //     _path = null;
  //   });
  //   final pickedFile = await _imagePicker?.pickImage(source: source);
  //   if (pickedFile != null) {
  //     _processPickedFile(pickedFile);
  //   }
  //   setState(() {});
  // }

  void _switchScreenMode() {
    if (_mode == ScreenMode.liveFeed) {
      setState(() {
        _mode = ScreenMode.gallery;
      });
      _stopLiveFeed();
    } else {
      _mode = ScreenMode.liveFeed;
      _startLiveFeed();
    }
    if (widget.onScreenModeChanged != null) {
      widget.onScreenModeChanged!(_mode);
    }
    setState(() {});
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );
    await _controller?.initialize();
    if (!mounted) {
      return;
    }
    _controller?.getMinZoomLevel().then((value) {
      zoomLevel = value;
      minZoomLevel = value;
    });
    _controller?.getMaxZoomLevel().then((value) {
      maxZoomLevel = value;
    });
    _controller?.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    processImage(inputImage);
  }

  Future<void> processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;
    final recognizedText = await _textRecognizer.processImage(inputImage);
    int step = 0;
    int partnerZero = partners.length;
    int line = 0;
    bool showReasonForError = false;
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
        final currentBlockText = chunks[x].trim().toLowerCase();
        if (step == 0) {
          if (firstPage &&
              currentBlockText == 'store' &&
              previousBlockText == 'home') {
            step = 1;
            continue;
          } else if (!firstPage &&
              RegExp(r'^\d{5}$').hasMatch(currentBlockText)) {
            step = 1;
            final Partner partner = Partner();
            partner.storeNumber = int.parse(currentBlockText);
            partners.add(partner);
            continue;
          }
        } else if (step == 1) {
          if (firstPage && currentBlockText == 'partner name') {
            step = 2;
            continue;
          } else if (!firstPage &&
              RegExp(r'^[a-z ,]*$').hasMatch(currentBlockText)) {
            step = 2;
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
          if (firstPage && currentBlockText == 'partner number') {
            step = 3;
            line = 0;
            continue;
          } else if (!firstPage &&
              RegExp(r'^us[\d]{1,8}$').hasMatch(currentBlockText)) {
            step = 3;
            line = 0;
            partners[partnerZero + line++].numbers = currentBlockText;
            continue;
          } else if (!RegExp(r'^[a-z ,]*$').hasMatch(currentBlockText) ||
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
          if (firstPage && currentBlockText == 'total tippable') {
            step = 4;
            line = 0;
            continue;
          } else if (!firstPage &&
              RegExp(r'^[\d]{1,2}\.[\d]{2}$').hasMatch(currentBlockText)) {
            step = 4;
            line = 0;
            partners[partnerZero + line++].hours =
                double.parse(currentBlockText);
            continue;
          } else if (currentBlockText == 'total tippable hours:') {
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
          if (partnerZero + line == partners.length) {
            if (RegExp(r'^[\d]*\.[\d]{2}$').hasMatch(currentBlockText)) {
              totalHours = double.parse(currentBlockText);
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
    if (partners.length > partnerZero) {
      if (needAnotherPage) {
        firstPage = false;
      } else if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          SummaryPage.routeName,
          ModalRoute.withName('/home'),
          arguments: SummaryArguments(partners, 318, totalHours),
        );
      }
      logger.d('Total Partners ${partners.length}');
    }
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = TextRecognizerPainter(
          recognizedText,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      _customPaint = null;
    }
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
}
