import 'dart:io';
import 'package:flutter/material.dart';
import 'package:document_scanner/document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/data_class.dart';
import 'package:untitled/summary_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? scannedDocument;
  Future<PermissionStatus>? cameraPermissionFuture;
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    cameraPermissionFuture = Permission.camera.request();
    super.initState();
  }

  List<Partner> partners = [];

  var logger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    printer: PrettyPrinter(), // Use the PrettyPrinter to format and logger.d log
    output: null, // Use the default LogOutput (-> send everything to console)
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: FutureBuilder<PermissionStatus>(
            future: cameraPermissionFuture,
            builder: (BuildContext context,
                AsyncSnapshot<PermissionStatus> permissionSnapshot) {
              if (permissionSnapshot.connectionState == ConnectionState.done) {
                if (permissionSnapshot.data!.isGranted) {
                  return Column(
                    children: <Widget>[
                      FutureBuilder<Widget>(
                        future: body(context),
                        builder: (BuildContext bodyContext,
                            AsyncSnapshot bodySnapshot) {
                          if (bodySnapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return Expanded(
                            child: bodySnapshot.data!,
                          );
                        },
                      ),
                    ],
                  );
                } else {
                  return const Center(
                    child: Text("camera permission denied"),
                  );
                }
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          )),
    );
  }

  Future<Widget> body(BuildContext context) async {
    int partnersZero = 0;
    if (scannedDocument != null) {
      bool firstPage = true;
      if (partners.isNotEmpty) {
        logger.d('Not first page');
        firstPage = false;
      }
      try {
        final InputImage inputImage = InputImage.fromFile(scannedDocument!);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        int step = firstPage ? 0 : 1;
        int lineNumber = 0;
        partnersZero = partners.length;
        bool needAnotherPage = firstPage ? false : true;
        bool checkingForEnd = false;
        double totalHours = 0.0;
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            logger.d(line.text);
            if (!firstPage) {
              if (step == 1) {
                if (!line.text.contains(RegExp(r'[0-9]'))) {
                  step = 2;
                  partners[partnersZero + lineNumber++].name = line.text;
                  continue;
                }
                final Partner partner = Partner();
                partner.storeNumber = int.parse(line.text);
                partners.add(partner);
              } else if (step == 2) {
                if (line.text.substring(0, 2) == 'US') {
                  step = 3;
                  lineNumber = 0;
                  partners[partnersZero + lineNumber++].numbers = line.text;
                  continue;
                }
                partners[partnersZero + lineNumber++].name = line.text;
              } else if (step == 3) {
                if (line.text.contains('Total')) {
                  logger.d('On last page');
                  needAnotherPage = false;
                  continue;
                } else if (line.text.substring(0, 2) != 'US' &&
                    line.text.contains(RegExp(r'[0-9]'))) {
                  step = 4;
                  lineNumber = 0;
                  partners[partnersZero + lineNumber++].hours =
                      double.parse(line.text);
                  continue;
                }
                partners[partnersZero + lineNumber++].numbers = line.text;
              } else if (step == 4) {
                if (!needAnotherPage &&
                    (partnersZero + lineNumber) >= partners.length) {
                  totalHours = double.parse(line.text);
                  continue;
                }
                partners[partnersZero + lineNumber++].hours =
                    double.parse(line.text);
              }
              continue;
            }
            if (step == 0 &&
                line.text.contains('Store') &&
                !line.text.contains('Store Number')) {
              step = 1;
              continue;
            } else if (step == 1) {
              if (line.text.contains('Name')) {
                step = 2;
                continue;
              } else if (line.text.contains('Partner')) {
                continue;
              }
              final Partner partner = Partner();
              partner.storeNumber = int.parse(line.text);
              partners.add(partner);
            } else if (step == 2) {
              if (line.text.contains('Number')) {
                step = 3;
                lineNumber = 0;
                continue;
              } else if (line.text.contains('Partner')) {
                continue;
              }
              partners[lineNumber++].name = line.text;
            } else if (step == 3) {
              if (line.text.contains('Hours')) {
                if (!checkingForEnd) {
                  checkingForEnd = true;
                }
                step = 4;
                lineNumber = 0;
                continue;
              } else if (line.text.contains('Total') ||
                  line.text.contains('Tippable')) {
                continue;
              }
              partners[lineNumber++].numbers = line.text;
            } else if (step == 4) {
              if (checkingForEnd) {
                if (line.text.contains(RegExp(r'[0-9]'))) {
                  needAnotherPage = true;
                } else {
                  checkingForEnd = false;
                  continue;
                }
              }
              partners[lineNumber++].hours = double.parse(line.text);
            }
          }
        }

        textRecognizer.close();
        logger.d('Need another page: $needAnotherPage');
        for (Partner partner in partners) {
          logger.d(partner);
        }
        if (needAnotherPage) {
          scannedDocument = null;
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Scan Next Page')));
          }
          setState(() {});
        } else {
          if (mounted) {
            showDialog(
                context: context,
                builder: (BuildContext popupContext) {
                  TextEditingController controller = TextEditingController();

                  return AlertDialog(
                    title: const Text('Enter Total Tips'),
                    content: TextField(
                      controller: controller,
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(popupContext);
                            Navigator.push(
                                popupContext,
                                MaterialPageRoute(
                                    builder: (context) => SummaryPage(
                                          TipHelper(),
                                          partners: partners,
                                          totalHours: totalHours,
                                          totalTips: int.parse(controller.text),
                                        )));
                          },
                          child: const Text('Ok'))
                    ],
                  );
                });
          }
        }
      } catch (e) {
        logger.d('Error: $e');
        setState(() {
          if (!firstPage) {
            while (partners.length > partnersZero) {
              partners.removeAt(partnersZero);
            }
          } else {
            partners = [];
          }
          scannedDocument = null;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Rescan Page')));
        });
      }
    }

    return scannedDocument != null
        ? Image(
            image: FileImage(scannedDocument!),
          )
        : DocumentScanner(
            // documentAnimation: false,
            noGrayScale: true,
            onDocumentScanned: (ScannedImage scannedImage) {
              logger.d("document : ${scannedImage.croppedImage!}");

              setState(() {
                scannedDocument = scannedImage.getScannedDocumentAsFile();
                // imageLocation = image;
              });
            },
          );
  }
}

class Partner {
  int storeNumber = -1;
  String name = '';
  String numbers = '';
  double hours = -1.0;
  int tipAmount = -1;

  Partner();

  @override
  toString() {
    return '\nPartner:\nName: $name\nStore Number: ${storeNumber != -1 ? storeNumber : ''}\nNumbers: $numbers\nHours: ${hours != -1.0 ? hours : ''}\nTip Amount: ${tipAmount != -1 ? tipAmount : ''}\n';
  }
}
