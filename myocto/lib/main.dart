import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'statefulwrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:flutter/services.dart';

import 'screens/print_screen.dart';

void main() {
  //SharedPreferences.setMockInitialValues({});
  runApp(App());
}

class ScalingBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    globals.logicWidth = 720;
    globals.logicHeight = 1500;
    double ratio =
        WidgetsBinding.instance.window.physicalSize.width / globals.logicWidth;
    globals.logicHeight =
        WidgetsBinding.instance.window.physicalSize.height / ratio;
    return SizedBox.expand(
        child: Container(
            color: Colors.blueGrey,
            child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: globals.logicWidth,
                  height: globals.logicHeight,
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
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', ''), // English, no country code
          const Locale('pl', ''), // Polish, no country code
        ],
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
