import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'settings_screen.dart';
import 'print_screen.dart';
import '../globals.dart' as globals;

class FileBox extends StatelessWidget {
  final String _fileName;
  FileBox(this._fileName) : super();

  @override
  Widget build(BuildContext context) {
    double logicWidth = WidgetsBinding.instance.window.physicalSize.width;
    double logicHeight = WidgetsBinding.instance.window.physicalSize.height;
    return SizedBox.expand(
        child: Container(
            color: Colors.blueGrey,
            child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: logicWidth,
                  height: logicHeight,
                  child: FileScreen(_fileName),
                ))));
  }
}

class FileScreen extends StatelessWidget {
  final String _fileName;
  const FileScreen(this._fileName) : super();
  void _showAlert(BuildContext context, String stext) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: Text(stext),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Align(
        alignment: Alignment(0.0, 0.34),
        child: SizedBox(
          width: 520.0,
          height: 1280.0,
          child: Column(
            children: <Widget>[
              Spacer(flex: 201),
// Group: octopus

              SizedBox(
                width: 292.63,
                height: 319.0,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image(image: AssetImage('images/octopus.png'))),
                  ],
                ),
              ),
              Spacer(flex: 50),
              Text(
                'Witamy w MyOcto',
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
                alignment: Alignment(-0.02, 0.0),
                child: Text(
                  'Wybrano plik',
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
              Spacer(flex: 57),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  alignment: Alignment(-0.28, -0.04),
                  width: 520.0,
                  height: 200.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    color: const Color(0xFF1E1E1E),
                  ),
                  child: SizedBox(
                    width: 520.0,
                    height: 100.0,
                    child: Row(
                      children: <Widget>[
                        Spacer(flex: 30),
                        Align(
                            alignment: Alignment.center,
                            child: Image(image: AssetImage('images/file.png'))),
                        Spacer(flex: 30),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 318.0,
                            child: Column(
                              children: <Widget>[
                                Spacer(flex: 10),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    _fileName,
                                    style: TextStyle(
                                      fontFamily: 'HK Grotesk',
                                      fontSize: 30.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      height: 0.97,
                                    ),
                                  ),
                                ),
                                //Spacer(flex: 10),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    'GCODE',
                                    style: TextStyle(
                                      fontFamily: 'HK Grotesk',
                                      fontSize: 30.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      height: 1.13,
                                    ),
                                  ),
                                ),
                                Spacer(flex: 10),
                              ],
                            ),
                          ),
                        ),
                        Spacer(flex: 30),
                      ],
                    ),
                  ),
                ),
              ),
              Spacer(flex: 40),
              InkWell(
                onTap: () async {
                  try {
                    final String api_url = globals.api_url;
                    print(api_url);
                    Socket s = await Socket.connect(api_url, 55555);
                    await s.write('print:' + _fileName + "\n");
                    await s.close();
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new PrintBox(_fileName)));
                  } catch (e) {
                    print(e.toString());
                    _showAlert(context, e.toString());
                  }
                },
                child:
// Group: Group 11
                    Container(
                  alignment: Alignment(0.0, 0.02),
                  width: 520.0,
                  height: 101.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Drukuj',
                    style: TextStyle(
                      fontFamily: 'HK Grotesk',
                      fontSize: 35.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 0.97,
                    ),
                    textAlign: TextAlign.center,
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
                  print('onTap Ustawienia drukarki');
                },
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text(
                    'Ustawienia drukarki',
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
