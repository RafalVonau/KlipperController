import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:flutter/services.dart';

import 'screens/print_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //SharedPreferences.setMockInitialValues({});
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MyOcto",
      home: HomeScreen(),
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
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loading = true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      _getThingsOnStartup().then((v) {
        setState(() {
          _loading = false;
        });
      });
      return Center(child: CircularProgressIndicator());
    } else {
      return ScalingBox();
    }
  }

  Future _getThingsOnStartup() async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    globals.prefs = await _prefs;
    globals.api_url = (globals.prefs?.getString('api_url') ?? '192.168.2.62');
    globals.head_temp = (globals.prefs?.getInt('head_temp') ?? 200);
    globals.bed_temp = (globals.prefs?.getInt('bed_temp') ?? 65);
  }
}

class ScalingBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    globals.logicWidth = 720;
    globals.logicHeight = 1500;
    final wndi = WidgetsBinding.instance!;
    final wnd = wndi.window;
    double ratio = wnd.physicalSize.width / globals.logicWidth;
    globals.logicHeight = wnd.physicalSize.height / ratio;
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
