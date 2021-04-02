import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_screen.dart';
import 'file_screen.dart';
import 'sdlist_screen.dart';
import 'print_screen.dart';
import 'pick_screen.dart';
import '../globals.dart' as globals;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension FileExtention on FileSystemEntity {
  String get name {
    return this?.path?.split("/")?.last;
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
        body: Align(
          alignment: Alignment(0.0, 0.34),
          child: SizedBox(
            width: 600.0,
            height: 1280.0,
            child: Column(
              children: <Widget>[
                Spacer(flex: 201),
// Group: octopus
                InkWell(
                  onLongPress: () {
                    /* Print from SD (local files on PI) */
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new SDListScreen()));
                  },
                  onTap: () {
                    /* Go to print page  */
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new PrintBox('')));
                  },
                  child: SizedBox(
                    width: 292.63,
                    height: 319.0,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        Image(image: AssetImage('images/octopus.png'))
                      ],
                    ),
                  ),
                ),
                Spacer(flex: 57),
                Text(
                  AppLocalizations.of(context).welcome,
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 56.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 0.88,
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacer(flex: 20),
                Align(
                  alignment: Alignment(-0.04, 0.0),
                  child: Text(
                    AppLocalizations.of(context).addfilestoqueue,
                    style: TextStyle(
                      fontFamily: 'HK Grotesk',
                      fontSize: 40.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 0.85,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Spacer(flex: 198),
                InkWell(
                  onLongPress: () {
                    /* ShortCut for uload file to SD card. */
                    uploadFile();
                  },
                  onTap: () {
                    /* Go to select file source page */
                     Navigator.push(
                        context,
                        new MaterialPageRoute(builder: (context) => new PickBox()));                    
                  },
                  child:
// Group: Group 9
                      Container(
                    alignment: Alignment(-0.48, -0.04),
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
                          Spacer(flex: 60),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: SvgPicture.string(
                              // plus
                              '<svg viewBox="0.0 0.0 80.0 80.0" ><path  d="M 40 0 C 17.943115234375 0 0 17.943115234375 0 40 C 0 62.05688858032227 17.943115234375 80 40 80 C 62.05688858032227 80 80 62.05688858032227 80 40 C 80 17.943115234375 62.05688858032227 0 40 0 Z M 40 0" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-103.5, -103.5)" d="M 161.0010986328125 146.834228515625 L 146.834228515625 146.834228515625 L 146.834228515625 161.0010986328125 C 146.834228515625 162.84130859375 145.34130859375 164.334228515625 143.5010986328125 164.334228515625 C 141.660888671875 164.334228515625 140.16796875 162.84130859375 140.16796875 161.0010986328125 L 140.16796875 146.834228515625 L 126.001091003418 146.834228515625 C 124.1608963012695 146.834228515625 122.6679611206055 145.34130859375 122.6679611206055 143.5010986328125 C 122.6679611206055 141.660888671875 124.1608963012695 140.16796875 126.001091003418 140.16796875 L 140.16796875 140.16796875 L 140.16796875 126.001091003418 C 140.16796875 124.1608963012695 141.660888671875 122.6679611206055 143.5010986328125 122.6679611206055 C 145.34130859375 122.6679611206055 146.834228515625 124.1608963012695 146.834228515625 126.001091003418 L 146.834228515625 140.16796875 L 161.0010986328125 140.16796875 C 162.84130859375 140.16796875 164.334228515625 141.660888671875 164.334228515625 143.5010986328125 C 164.334228515625 145.34130859375 162.84130859375 146.834228515625 161.0010986328125 146.834228515625 Z M 161.0010986328125 146.834228515625" fill="#fafafa" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                              width: 80.0,
                              height: 80.0,
                            ),
                          ),
                          Spacer(flex: 40),
                          SizedBox(
                            width: 180.0,
                            height: 75.0,
                            child: Column(
                              children: <Widget>[
                                Spacer(flex: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppLocalizations.of(context).addfiles,
                                    style: TextStyle(
                                      fontFamily: 'HK Grotesk',
                                      fontSize: 34.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      height: 0.97,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppLocalizations.of(context).choicefile,
                                    style: TextStyle(
                                      fontFamily: 'HK Grotesk',
                                      fontSize: 28.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      height: 1.13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(flex: 150),
                        ],
                      ),
                    ),
                  ),
                ),
                Spacer(flex: 10),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new SettingsBox()));
                  },
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Text(
                      AppLocalizations.of(context).printersettings,
                      style: TextStyle(
                        fontFamily: 'HK Grotesk',
                        fontSize: 30.0,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        height: 1.13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Spacer(flex: 100),
              ],
            ),
          ),
        ),
      );
    }
  }
}
