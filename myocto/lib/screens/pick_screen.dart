import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../globals.dart' as globals;
import 'file_screen.dart';
import 'sdlist_screen.dart';

class PickBox extends StatelessWidget {
  PickBox() : super();
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
        child: Container(
            color: Colors.blueGrey,
            child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: globals.logicWidth,
                  height: globals.logicHeight,
                  child: PickScreen(),
                ))));
  }
}

class PickScreen extends StatefulWidget {
  @override
  _PickScreenState createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  bool _uploading;

  @override
  void initState() {
    super.initState();
    _uploading = false;
  }

  // Schow dialog on error
  void _showAlert(BuildContext context, String stext) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: Text(stext),
            ));
  }

  // upload file to PI filesystem.
  void uploadFile() async {
    final String api_url = globals.api_url;
    String name;
    bool ok = false;

    setState(() => _uploading = true);

    if (Platform.isAndroid) {
      final FilePickerResult result =
          await FilePicker.platform.pickFiles(sendToIP: api_url);
      if (result != null) {
        var rfile = result.files.first;
        name = rfile.name.split("/")?.last;
        ok = true;
      }
    } else {
      final FilePickerResult result =
          await FilePicker.platform.pickFiles(withData: true);
      if (result != null) {
        var rfile = result.files.first;
        name = rfile.name.split("/")?.last;
        try {
          Socket s = await Socket.connect(api_url, 55555);
          s.write("download:$name\n");
          //await s.addStream(file.openRead());
          s.add(rfile.bytes); // one second faster
          await s.flush();
          await s.close();
          s.destroy();
          ok = true;
        } catch (e) {
          print(e.toString());
          _showAlert(context, e.toString());
        }
      }
    }
    setState(() => _uploading = false);
    await FilePicker.platform.clearTemporaryFiles();
    if (ok) {
      print('ok: data written');
      Navigator.push(context,
          new MaterialPageRoute(builder: (context) => new FileBox(name)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uploading) {
      return Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 520.0,
            //height: 1280.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 600, height: 100),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 520.0,
                    height: 59.0,
                    child: Row(
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            AppLocalizations.of(context).cancel,
                            style: TextStyle(
                              fontFamily: 'HK Grotesk',
                              fontSize: 30.0,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                              height: 1.13,
                            ),
                          ),
                        ),
                        Spacer(flex: 219),
                        Text(
                          AppLocalizations.of(context).addfiles,
                          style: TextStyle(
                            fontFamily: 'HK Grotesk',
                            fontSize: 45.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.09,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
                Spacer(flex: 400),
                SizedBox(width: 600, height: 40),
                /* From cell phone */
                InkWell(
                  onTap: () {
                    uploadFile();
                  },
                  child: Container(
                    alignment: Alignment(0.01, -0.04),
                    width: 520.0,
                    height: 200.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      color: const Color(0xFF1E1E1E),
                    ),
                    child: SizedBox(
                      width: 520.0,
                      height: 85.0,
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 50, height: 40),
                          Align(
                            alignment: Alignment.center,
                            child: // Rotate image 45 degrees
                                Transform.rotate(
                              angle: 3.14 / 180 * 270,
                              alignment: Alignment.center,
                              child: SvgPicture.string(
                                // mobile-calibration
                                '<svg viewBox="16.9 1.0 80.0 48.89" ><path transform="translate(13.9, 0.0)" d="M 83.00003814697266 41.48446655273438 L 83.00003814697266 37.66668319702148 L 83.00003814697266 13.22222900390625 L 83.00003814697266 9.404449462890625 C 83.00003814697266 4.768892288208008 78.88892364501953 1 73.83114624023438 1 L 12.16444778442383 1 C 7.111112594604492 1 3.000000238418579 4.768892288208008 3.000000238418579 9.404449462890625 L 3.000000238418579 41.48891067504883 C 3.000000238418579 46.12002182006836 7.111112594604492 49.88891983032227 12.16444778442383 49.88891983032227 L 73.83114624023438 49.88891983032227 C 78.88892364501953 49.88891983032227 83.00003814697266 46.12002182006836 83.00003814697266 41.48446655273438 Z" fill="#2196f3" stroke="#707070" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(19.07, 4.73)" d="M 7.833335876464844 39.04512786865234 C 5.993334293365479 39.04512786865234 4.500000476837158 37.67623901367188 4.500000476837158 35.98734664916992 L 4.500000476837158 5.431778907775879 C 4.500000476837158 3.742888450622559 5.993334293365479 2.373998641967773 7.833335876464844 2.373998641967773 L 68.94448089599609 2.373998641967773 C 70.78447723388672 2.373998641967773 72.27781677246094 3.742888450622559 72.27781677246094 5.431778907775879 L 72.27781677246094 6.960667610168457 C 72.27781677246094 8.649558067321777 70.78447723388672 10.01400470733643 68.94448089599609 10.01400470733643 C 67.10448455810547 10.01400470733643 65.61113739013672 11.38289356231689 65.61113739013672 13.0717830657959 L 65.61113739013672 28.35179328918457 C 65.61113739013672 30.04068565368652 67.10448455810547 31.40956878662109 68.94448089599609 31.40956878662109 C 70.78447723388672 31.40956878662109 72.27781677246094 32.77845764160156 72.27781677246094 34.46290588378906 L 72.27781677246094 35.99179458618164 C 72.27781677246094 37.68068695068359 70.78447723388672 39.0495719909668 68.94448089599609 39.0495719909668 L 7.833335876464844 39.0495719909668 Z" fill="#1e1e1e" stroke="#707070" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                width: 73.0,
                                height: 45.0,
                              ),
                            ),
                          ),
                          SizedBox(width: 30, height: 40),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              width: 315.0,
                              child: Column(
                                children: <Widget>[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      AppLocalizations.of(context).fromphone,
                                      style: TextStyle(
                                        fontFamily: 'HK Grotesk',
                                        fontSize: 35.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Text(
                                      AppLocalizations.of(context).fileapp,
                                      style: TextStyle(
                                        fontFamily: 'HK Grotesk',
                                        fontSize: 24.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 50, height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 600, height: 40),
                /* Local file */
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new SDListScreen()));
                  },
                  child: Container(
                    alignment: Alignment(-0.01, -0.04),
                    width: 520.0,
                    height: 200.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      color: const Color(0xFF1E1E1E),
                    ),
                    child: SizedBox(
                      width: 520.0,
                      height: 85.0,
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 50, height: 40),
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                                width: 73.0,
                                height: 80.0,
                                child: Image(
                                    image: AssetImage(
                                        'images/octopus_small.png'))),
                          ),
                          SizedBox(width: 30, height: 40),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              width: 315.0,
                              child: Column(
                                children: <Widget>[
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      AppLocalizations.of(context).frompi,
                                      style: TextStyle(
                                        fontFamily: 'HK Grotesk',
                                        fontSize: 35.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Text(
                                      AppLocalizations.of(context).frompitext,
                                      style: TextStyle(
                                        fontFamily: 'HK Grotesk',
                                        fontSize: 24.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 50, height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 600, height: 80),
              ],
            ),
          ),
        ),
      );
    }
  }
}
