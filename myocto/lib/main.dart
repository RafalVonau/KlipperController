import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'statefulwrapper.dart';
//import 'package:flutter/services.dart';

import 'screens/print_screen.dart';

void main() {
  //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
//      .then((_) {
    runApp(App());
//  });
  //runApp(App());
}

class ScalingBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //double logicWidth = 720;
    //double logicHeight = 1280;
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
                  child: MainScreen(),
                  //child: PrintScreen('ala.gcode'),
                ))));
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulWrapper(
      onInit: () {
        _getThingsOnStartup().then((value) {
          print('Async done');
        });
      },
      child: MaterialApp(
        title: "MyOcto",
        home: ScalingBox(),
        theme: ThemeData(primaryColor: Colors.lightGreen),
      ),
    );
  }

  Future _getThingsOnStartup() async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    globals.prefs = await _prefs;
    globals.api_url = (globals.prefs.getString('api_url') ?? '192.168.2.62');
    globals.head_temp = (globals.prefs.getInt('head_temp') ?? 200);
    globals.bed_temp = (globals.prefs.getInt('bed_temp') ?? 65);
  }
}
