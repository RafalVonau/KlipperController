import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'rc_screen.dart';
import 'edit_screen.dart';
import '../globals.dart' as globals;

class SettingsBox extends StatelessWidget {
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
                  child: SettingScreen(),
                ))));
  }
}

class SettingScreen extends StatelessWidget {
  SettingScreen({Key key}) : super(key: key);
  final TextEditingController _api_url_ctl = TextEditingController();
  final TextEditingController _head_temp_ctl = TextEditingController();
  final TextEditingController _bed_temp_ctl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _api_url_ctl.text = globals.api_url;
    _head_temp_ctl.text = globals.head_temp.toString();
    _bed_temp_ctl.text = globals.bed_temp.toString();
    Widget res = Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 520.0,
          height: 1280.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              //Spacer(flex: 100),
              SizedBox(width: 600, height: 100),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 520.0,
                  height: 59.0,
                  child: Row(
                    children: <Widget>[
                      InkWell(
                        onTap: () async {
                          print(_api_url_ctl.text);
                          globals.api_url = _api_url_ctl.text;
                          await globals.prefs
                              .setString('api_url', globals.api_url);
                          globals.head_temp = int.parse(_head_temp_ctl.text);
                          await globals.prefs
                              .setInt('head_temp', globals.head_temp);
                          globals.bed_temp = int.parse(_bed_temp_ctl.text);
                          await globals.prefs
                              .setInt('bed_temp', globals.bed_temp);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text(
                            'Zamknij',
                            style: TextStyle(
                              fontFamily: 'HK Grotesk',
                              fontSize: 30.0,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                              height: 1.13,
                            ),
                          ),
                        ),
                      ),
                      Spacer(flex: 190),
                      Text(
                        'Ustawienia',
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
              //Spacer(flex: 43),
              SizedBox(width: 600, height: 30),
              Align(
                alignment: Alignment(-0.89, 0.0),
                child: Text(
                  'IP drukarki',
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 30.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.13,
                  ),
                ),
              ),
              //Spacer(flex: 18),
              SizedBox(width: 600, height: 10),
              Container(
                alignment: Alignment(-0.76, 0.0),
                width: 520.0,
                height: 101.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  color: const Color(0xFF1E1E1E),
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '192.168.1.62',
                    contentPadding: EdgeInsets.all(30.0),
                  ),
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 30.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.13,
                  ),
                  controller: _api_url_ctl,
                ),
              ),
              //Spacer(flex: 20),
              SizedBox(width: 600, height: 20),
              Align(
                alignment: Alignment(-0.83, 0.0),
                child: Text(
                  'Temperatura głowicy',
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 30.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.13,
                  ),
                ),
              ),
              //Spacer(flex: 18),
              SizedBox(width: 600, height: 10),
              Container(
                alignment: Alignment(-0.82, 0.0),
                width: 520.0,
                height: 101.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  color: const Color(0xFF1E1E1E),
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '200°C',
                    contentPadding: EdgeInsets.all(30.0),
                  ),
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 30.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.13,
                  ),
                  controller: _head_temp_ctl,
                  keyboardType: TextInputType.number,
                ),
              ),
              //Spacer(flex: 20),
              SizedBox(width: 600, height: 20),
              Align(
                alignment: Alignment(-0.85, 0.0),
                child: Text(
                  'Temperatura łóżka',
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 30.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.13,
                  ),
                ),
              ),
              //Spacer(flex: 18),
              SizedBox(width: 600, height: 10),
              Container(
                alignment: Alignment(-0.82, 0.0),
                width: 520.0,
                height: 101.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  color: const Color(0xFF1E1E1E),
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '60°C',
                    contentPadding: EdgeInsets.all(30.0),
                  ),
                  style: TextStyle(
                    fontFamily: 'HK Grotesk',
                    fontSize: 30.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.13,
                  ),
                  controller: _bed_temp_ctl,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 600, height: 60),
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) => new EditScreen()));
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
                                    'Konfiguracja Klippera',
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
                                    'Edytuj plik cfg',
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
              Spacer(flex: 20),
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      new MaterialPageRoute(builder: (context) => new RCBox()));
                },
                child:
// Group: Group 16
                    Container(
                  alignment: Alignment(0.28, -0.04),
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
                        Spacer(flex: 40),
                        Align(
                          alignment: Alignment.center,
                          child:
// Group: remote-control

                              SizedBox(
                            width: 50.51,
                            height: 80.0,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: <Widget>[
                                SvgPicture.string(
                                  // Path 39
                                  '<svg viewBox="153.78 63.21 50.51 80.0" ><path transform="translate(0.0, -124.98)" d="M 197.4376220703125 188.1950073242188 L 160.6302795410156 188.1950073242188 C 156.8462677001953 188.1950073242188 153.7789916992188 191.2625274658203 153.7789916992188 195.0462951660156 L 153.7789916992188 261.3436889648438 C 153.7789916992188 265.1277160644531 156.8465118408203 268.1949768066406 160.6302795410156 268.1949768066406 L 197.4376220703125 268.1949768066406 C 201.2216339111328 268.1949768066406 204.2888946533203 265.1274719238281 204.2888946533203 261.3436889648438 L 204.2888946533203 195.0462799072266 C 204.2888946533203 191.2625274658203 201.2213745117188 188.1949920654297 197.4376220703125 188.1949920654297 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                  width: 50.51,
                                  height: 80.0,
                                ),
                                Positioned(
                                  bottom: 8.0,
                                  child: SvgPicture.string(
                                    // Group 8
                                    '<svg viewBox="0.0 0.0 36.35 35.65" ><path transform="translate(-182.44, -419.4)" d="M 186.1793518066406 455.04833984375 C 184.2759704589844 455.04833984375 182.6522827148438 453.60595703125 182.4561157226562 451.6739501953125 C 182.2132568359375 449.33251953125 184.2203826904297 447.3464050292969 186.5459899902344 447.5840454101562 C 188.3322296142578 447.7673950195312 189.7165222167969 449.168212890625 189.9003601074219 450.9384460449219 C 190.1172637939453 453.0747680664062 188.4402160644531 455.04833984375 186.1793365478516 455.04833984375 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-226.42, -419.4)" d="M 244.5993499755859 455.04833984375 C 242.6959686279297 455.04833984375 241.0722808837891 453.60595703125 240.8761138916016 451.6739501953125 C 240.6332397460938 449.33251953125 242.640380859375 447.3464050292969 244.9659881591797 447.5840454101562 C 246.7522430419922 447.7673950195312 248.1365356445312 449.168212890625 248.3203430175781 450.9384460449219 C 248.5375061035156 453.0747680664062 246.8604431152344 455.04833984375 244.5993347167969 455.04833984375 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-270.41, -419.4)" d="M 303.0193481445312 455.04833984375 C 301.1159973144531 455.04833984375 299.4923095703125 453.60595703125 299.296142578125 451.6739501953125 C 299.0532836914062 449.33251953125 301.0603942871094 447.3464050292969 303.385986328125 447.5840454101562 C 305.1722412109375 447.7673950195312 306.5565490722656 449.168212890625 306.7403564453125 450.9384460449219 C 306.95751953125 453.0747680664062 305.2804870605469 455.04833984375 303.0193481445312 455.04833984375 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-182.44, -376.49)" d="M 186.1793518066406 398.0542907714844 C 184.2759704589844 398.0542907714844 182.6522827148438 396.6119384765625 182.4561157226562 394.6799011230469 C 182.2132568359375 392.3385009765625 184.2203826904297 390.3523559570312 186.5459899902344 390.5900268554688 C 188.3322296142578 390.7733459472656 189.7165222167969 392.1741943359375 189.9003601074219 393.9444274902344 C 190.1172637939453 396.0807495117188 188.4402160644531 398.0542907714844 186.1793365478516 398.0542907714844 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-226.42, -376.49)" d="M 244.5993499755859 398.0542907714844 C 242.6959686279297 398.0542907714844 241.0722808837891 396.6119384765625 240.8761138916016 394.6799011230469 C 240.6332397460938 392.3385009765625 242.640380859375 390.3523559570312 244.9659881591797 390.5900268554688 C 246.7522430419922 390.7733459472656 248.1365356445312 392.1741943359375 248.3203430175781 393.9444274902344 C 248.5375061035156 396.0807495117188 246.8604431152344 398.0542907714844 244.5993347167969 398.0542907714844 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-270.41, -376.49)" d="M 303.0193481445312 398.0542907714844 C 301.1159973144531 398.0542907714844 299.4923095703125 396.6119384765625 299.296142578125 394.6799011230469 C 299.0532836914062 392.3385009765625 301.0603942871094 390.3523559570312 303.385986328125 390.5900268554688 C 305.1722412109375 390.7733459472656 306.5565490722656 392.1741943359375 306.7403564453125 393.9444274902344 C 306.95751953125 396.0807495117188 305.2804870605469 398.0542907714844 303.0193481445312 398.0542907714844 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-182.44, -333.58)" d="M 186.1793518066406 341.0603332519531 C 184.2759704589844 341.0603332519531 182.6522827148438 339.6179504394531 182.4561157226562 337.6859436035156 C 182.2132568359375 335.3447570800781 184.2203826904297 333.3583984375 186.5459899902344 333.5960693359375 C 188.3322296142578 333.7793884277344 189.7165222167969 335.1802368164062 189.9003601074219 336.950439453125 C 190.1172637939453 339.0867614746094 188.4402160644531 341.0603332519531 186.1793365478516 341.0603332519531 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-226.42, -333.58)" d="M 244.5993499755859 341.0603332519531 C 242.6959686279297 341.0603332519531 241.0722808837891 339.6179504394531 240.8761138916016 337.6859436035156 C 240.6332397460938 335.3447570800781 242.640380859375 333.3583984375 244.9659881591797 333.5960693359375 C 246.7522430419922 333.7793884277344 248.1365356445312 335.1802368164062 248.3203430175781 336.950439453125 C 248.5375061035156 339.0867614746094 246.8604431152344 341.0603332519531 244.5993347167969 341.0603332519531 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-270.41, -333.58)" d="M 303.0193481445312 341.0603332519531 C 301.1159973144531 341.0603332519531 299.4923095703125 339.6179504394531 299.296142578125 337.6859436035156 C 299.0532836914062 335.3447570800781 301.0603942871094 333.3583984375 303.385986328125 333.5960693359375 C 305.1722412109375 333.7793884277344 306.5565490722656 335.1802368164062 306.7403564453125 336.950439453125 C 306.95751953125 339.0867614746094 305.2804870605469 341.0603332519531 303.0193481445312 341.0603332519531 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 36.35,
                                    height: 35.65,
                                  ),
                                ),
                                Positioned(
                                  left: 7.0,
                                  bottom: 8.0,
                                  child: SvgPicture.string(
                                    // Path 56
                                    '<svg viewBox="160.86 127.29 5.62 7.48" ><path transform="translate(-21.58, -320.27)" d="M 186.1967620849609 451.6738891601562 C 186.0386352539062 450.1500244140625 186.8366546630859 448.7810668945312 188.0524291992188 448.0731811523438 C 187.60302734375 447.8120727539062 187.0933532714844 447.6403198242188 186.5451202392578 447.5840454101562 C 184.2195281982422 447.3463134765625 182.2126312255859 449.3327026367188 182.4552459716797 451.6738891601562 C 182.6516571044922 453.6056518554688 184.2751159667969 455.0482788085938 186.178466796875 455.0482788085938 C 186.8709869384766 455.0482788085938 187.5076751708984 454.8614501953125 188.0529327392578 454.5435180664062 C 187.0461730957031 453.96044921875 186.3235015869141 452.9205932617188 186.1967620849609 451.6738891601562 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  left: 21.0,
                                  bottom: 8.0,
                                  child: SvgPicture.string(
                                    // Path 57
                                    '<svg viewBox="175.29 127.29 5.62 7.48" ><path transform="translate(-65.56, -320.27)" d="M 244.6177062988281 451.6738891601562 C 244.4595794677734 450.1500244140625 245.2575836181641 448.7810668945312 246.473388671875 448.0731811523438 C 246.0239868164062 447.8120727539062 245.5142822265625 447.6403198242188 244.966064453125 447.5840454101562 C 242.6404571533203 447.3463134765625 240.6335754394531 449.3327026367188 240.8761901855469 451.6738891601562 C 241.0723419189453 453.6056518554688 242.696044921875 455.0482788085938 244.5994110107422 455.0482788085938 C 245.2919311523438 455.0482788085938 245.9286041259766 454.8614501953125 246.473876953125 454.5435180664062 C 245.4668426513672 453.96044921875 244.7441864013672 452.9205932617188 244.6176910400391 451.6738891601562 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  right: 8.0,
                                  bottom: 8.0,
                                  child: SvgPicture.string(
                                    // Path 58
                                    '<svg viewBox="189.73 127.29 5.62 7.48" ><path transform="translate(-109.55, -320.27)" d="M 303.0377502441406 451.6738891601562 C 302.8796081542969 450.1500244140625 303.6776428222656 448.7810668945312 304.8934326171875 448.0731811523438 C 304.4440307617188 447.8120727539062 303.934326171875 447.6403198242188 303.3861083984375 447.5840454101562 C 301.0605163574219 447.3463134765625 299.0535888671875 449.3327026367188 299.2962341308594 451.6738891601562 C 299.4924011230469 453.6056518554688 301.1160888671875 455.0482788085938 303.0194702148438 455.0482788085938 C 303.7119750976562 455.0482788085938 304.3486633300781 454.8614501953125 304.8939208984375 454.5435180664062 C 303.8871459960938 453.96044921875 303.1644897460938 452.9205932617188 303.0377502441406 451.6738891601562 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  left: 7.0,
                                  bottom: 22.0,
                                  child: SvgPicture.string(
                                    // Path 59
                                    '<svg viewBox="160.86 113.21 5.62 7.48" ><path transform="translate(-21.58, -277.36)" d="M 186.1967620849609 394.6799011230469 C 186.0386352539062 393.1560363769531 186.8366546630859 391.7868347167969 188.0524291992188 391.0792236328125 C 187.60302734375 390.8180541992188 187.0933532714844 390.6463928222656 186.5451202392578 390.5900268554688 C 184.2195281982422 390.3523559570312 182.2126312255859 392.3387451171875 182.4552459716797 394.6799011230469 C 182.6516571044922 396.6116943359375 184.2751159667969 398.0542907714844 186.178466796875 398.0542907714844 C 186.8709869384766 398.0542907714844 187.5076751708984 397.8677673339844 188.0529327392578 397.549560546875 C 187.0461730957031 396.9664916992188 186.3235015869141 395.9265747070312 186.1967620849609 394.6799011230469 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  left: 21.0,
                                  bottom: 22.0,
                                  child: SvgPicture.string(
                                    // Path 60
                                    '<svg viewBox="175.29 113.21 5.62 7.48" ><path transform="translate(-65.56, -277.36)" d="M 244.6177062988281 394.6799011230469 C 244.4595794677734 393.1560363769531 245.2575836181641 391.7868347167969 246.473388671875 391.0792236328125 C 246.0239868164062 390.8180541992188 245.5142822265625 390.6463928222656 244.966064453125 390.5900268554688 C 242.6404571533203 390.3523559570312 240.6335754394531 392.3387451171875 240.8761901855469 394.6799011230469 C 241.0723419189453 396.6116943359375 242.696044921875 398.0542907714844 244.5994110107422 398.0542907714844 C 245.2919311523438 398.0542907714844 245.9286041259766 397.8677673339844 246.473876953125 397.549560546875 C 245.4668426513672 396.9664916992188 244.7441864013672 395.9265747070312 244.6176910400391 394.6799011230469 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  right: 8.0,
                                  bottom: 22.0,
                                  child: SvgPicture.string(
                                    // Path 61
                                    '<svg viewBox="189.73 113.21 5.62 7.48" ><path transform="translate(-109.55, -277.36)" d="M 303.0377502441406 394.6799011230469 C 302.8796081542969 393.1560363769531 303.6776428222656 391.7868347167969 304.8934326171875 391.0792236328125 C 304.4440307617188 390.8180541992188 303.934326171875 390.6463928222656 303.3861083984375 390.5900268554688 C 301.0605163574219 390.3523559570312 299.0535888671875 392.3387451171875 299.2962341308594 394.6799011230469 C 299.4924011230469 396.6116943359375 301.1160888671875 398.0542907714844 303.0194702148438 398.0542907714844 C 303.7119750976562 398.0542907714844 304.3486633300781 397.8677673339844 304.8939208984375 397.549560546875 C 303.8871459960938 396.9664916992188 303.1644897460938 395.9265747070312 303.0377502441406 394.6799011230469 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  left: 7.0,
                                  top: 35.0,
                                  child: SvgPicture.string(
                                    // Path 62
                                    '<svg viewBox="160.86 99.13 5.62 7.48" ><path transform="translate(-21.58, -234.45)" d="M 186.1967620849609 337.6859130859375 C 186.0386352539062 336.1620483398438 186.8366546630859 334.7927856445312 188.0524291992188 334.0852355957031 C 187.60302734375 333.8240661621094 187.0933532714844 333.65234375 186.5451202392578 333.5960388183594 C 184.2195281982422 333.3583679199219 182.2126312255859 335.3447570800781 182.4552459716797 337.6859130859375 C 182.6516571044922 339.61767578125 184.2751159667969 341.0602722167969 186.178466796875 341.0602722167969 C 186.8709869384766 341.0602722167969 187.5076751708984 340.8737487792969 188.0529327392578 340.5555419921875 C 187.0461730957031 339.9724731445312 186.3235015869141 338.9325561523438 186.1967620849609 337.6859130859375 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  left: 21.0,
                                  top: 35.0,
                                  child: SvgPicture.string(
                                    // Path 63
                                    '<svg viewBox="175.29 99.13 5.62 7.48" ><path transform="translate(-65.56, -234.45)" d="M 244.6177062988281 337.6859130859375 C 244.4595794677734 336.1620483398438 245.2575836181641 334.7927856445312 246.473388671875 334.0852355957031 C 246.0239868164062 333.8240661621094 245.5142822265625 333.65234375 244.966064453125 333.5960388183594 C 242.6404571533203 333.3583679199219 240.6335754394531 335.3447570800781 240.8761901855469 337.6859130859375 C 241.0723419189453 339.61767578125 242.696044921875 341.0602722167969 244.5994110107422 341.0602722167969 C 245.2919311523438 341.0602722167969 245.9286041259766 340.8737487792969 246.473876953125 340.5555419921875 C 245.4668426513672 339.9724731445312 244.7441864013672 338.9325561523438 244.6176910400391 337.6859130859375 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  right: 8.0,
                                  top: 35.0,
                                  child: SvgPicture.string(
                                    // Path 64
                                    '<svg viewBox="189.73 99.13 5.62 7.48" ><path transform="translate(-109.55, -234.45)" d="M 303.0377502441406 337.6859130859375 C 302.8796081542969 336.1620483398438 303.6776428222656 334.7927856445312 304.8934326171875 334.0852355957031 C 304.4440307617188 333.8240661621094 303.934326171875 333.65234375 303.3861083984375 333.5960388183594 C 301.0605163574219 333.3583679199219 299.0535888671875 335.3447570800781 299.2962341308594 337.6859130859375 C 299.4924011230469 339.61767578125 301.1160888671875 341.0602722167969 303.0194702148438 341.0602722167969 C 303.7119750976562 341.0602722167969 304.3486633300781 340.8737487792969 304.8939208984375 340.5555419921875 C 303.8871459960938 339.9724731445312 303.1644897460938 338.9325561523438 303.0377502441406 337.6859130859375 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 5.62,
                                    height: 7.48,
                                  ),
                                ),
                                Positioned(
                                  top: 14.0,
                                  child: SizedBox(
                                    width: 7.48,
                                    height: 7.48,
                                    child: Stack(
                                      children: <Widget>[
                                        SvgPicture.string(
                                          // Path 65
                                          '<svg viewBox="175.29 77.45 7.48 7.48" ><path transform="translate(-65.56, -168.38)" d="M 244.5993499755859 253.3172760009766 C 242.6959686279297 253.3172760009766 241.0722808837891 251.8749237060547 240.8761138916016 249.9429016113281 C 240.6332397460938 247.6017456054688 242.640380859375 245.6153564453125 244.9659881591797 245.85302734375 C 246.7522430419922 246.0363616943359 248.1365356445312 247.4371948242188 248.3203430175781 249.2073974609375 C 248.5375061035156 251.34375 246.8604431152344 253.3172760009766 244.5993347167969 253.3172760009766 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                          width: 7.48,
                                          height: 7.48,
                                        ),
                                        SvgPicture.string(
                                          // Path 66
                                          '<svg viewBox="175.29 77.45 5.62 7.48" ><path transform="translate(-65.56, -168.38)" d="M 244.6177062988281 249.9429321289062 C 244.4595794677734 248.4190673828125 245.2575836181641 247.0500793457031 246.473388671875 246.3422546386719 C 246.0239868164062 246.0811157226562 245.5142822265625 245.9093933105469 244.966064453125 245.8530578613281 C 242.6404571533203 245.6153869628906 240.6335754394531 247.6017761230469 240.8761901855469 249.9429321289062 C 241.0723419189453 251.8747253417969 242.696044921875 253.3173217773438 244.5994110107422 253.3173217773438 C 245.2919311523438 253.3173217773438 245.9286041259766 253.1305236816406 246.473876953125 252.8125610351562 C 245.4668426513672 252.2294921875 244.7441864013672 251.1896057128906 244.6176910400391 249.9429321289062 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                          width: 5.62,
                                          height: 7.48,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 11.0,
                                  top: 11.0,
                                  child: SvgPicture.string(
                                    // Path 67
                                    '<svg viewBox="165.07 75.0 7.32 12.38" ><path transform="translate(-34.41, -160.92)" d="M 203.538330078125 247.7451324462891 L 200.5918731689453 244.7986755371094 C 199.1117248535156 243.3185119628906 199.1117248535156 240.9099273681641 200.5918731689453 239.4297485351562 L 203.538330078125 236.4832916259766 C 204.2839660644531 235.7379150390625 205.4925842285156 235.7379150390625 206.2379913330078 236.4832916259766 C 206.9833831787109 237.2286682128906 206.9833831787109 238.4375610351562 206.2379913330078 239.1829376220703 L 203.3065795898438 242.1143341064453 L 206.2379913330078 245.0457305908203 C 206.9833831787109 245.7911224365234 206.9833831787109 247 206.2379913330078 247.7453765869141 C 205.4925842285156 248.4905090332031 204.2839660644531 248.4907684326172 203.538330078125 247.7451324462891 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 7.32,
                                    height: 12.38,
                                  ),
                                ),
                                Positioned(
                                  top: 4.0,
                                  child: SvgPicture.string(
                                    // Path 68
                                    '<svg viewBox="172.84 67.23 12.38 7.32" ><path transform="translate(-58.1, -137.23)" d="M 240.0667114257812 211.2166442871094 L 237.1353149414062 208.2855072021484 L 234.2039184570312 211.2168884277344 C 233.4582824707031 211.9622802734375 232.2496643066406 211.9622802734375 231.5042724609375 211.2168884277344 C 230.7588806152344 210.4714965820312 230.7588806152344 209.2626342773438 231.5042724609375 208.5172424316406 L 234.4507446289062 205.5707702636719 C 235.9311218261719 204.0903778076172 238.3394775390625 204.0908660888672 239.8196411132812 205.5705261230469 L 242.766357421875 208.5172424316406 C 243.51171875 209.2626342773438 243.51171875 210.4714965820312 242.766357421875 211.2168884277344 C 242.0209655761719 211.9620361328125 240.8123168945312 211.9625244140625 240.0667114257812 211.2166442871094 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 12.38,
                                    height: 7.32,
                                  ),
                                ),
                                Positioned(
                                  top: 24.0,
                                  child: SvgPicture.string(
                                    // Path 69
                                    '<svg viewBox="172.84 87.84 12.38 7.32" ><path transform="translate(-58.1, -200.05)" d="M 234.4517517089844 294.0934143066406 L 231.5053100585938 291.14697265625 C 230.7599182128906 290.4015502929688 230.7599182128906 289.1926879882812 231.5053100585938 288.4472961425781 C 232.2506713867188 287.701904296875 233.4595642089844 287.701904296875 234.2049560546875 288.4472961425781 L 237.1361083984375 291.37841796875 L 240.0675048828125 288.4472961425781 C 240.8128662109375 287.701904296875 242.0217590332031 287.701904296875 242.7671508789062 288.4472961425781 C 243.5125122070312 289.1926879882812 243.5125122070312 290.4015502929688 242.7671508789062 291.14697265625 L 239.8206787109375 294.0934143066406 C 238.3402709960938 295.5735473632812 235.9319152832031 295.5735473632812 234.4517517089844 294.0934143066406 Z" fill="#2384d1" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 12.38,
                                    height: 7.32,
                                  ),
                                ),
                                Positioned(
                                  right: 11.0,
                                  top: 11.0,
                                  child: SvgPicture.string(
                                    // Path 70
                                    '<svg viewBox="185.68 75.0 7.32 12.38" ><path transform="translate(-97.23, -160.92)" d="M 283.4682922363281 247.7451324462891 C 282.722900390625 246.999755859375 282.722900390625 245.7908630371094 283.4682922363281 245.0454864501953 L 286.3996887207031 242.1140899658203 L 283.4685363769531 239.1829376220703 C 282.72314453125 238.4375610351562 282.72314453125 237.2286682128906 283.4685363769531 236.4832916259766 C 284.2141723632812 235.7379150390625 285.4227905273438 235.7379150390625 286.1681823730469 236.4832916259766 L 289.1146240234375 239.4297485351562 C 290.5982666015625 240.9131317138672 290.5985107421875 243.3150634765625 289.1146240234375 244.7986755371094 L 286.1681823730469 247.7451324462891 C 285.4223022460938 248.4907684326172 284.2139282226562 248.4907684326172 283.4682922363281 247.7451324462891 Z" fill="#2196f3" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                                    width: 7.32,
                                    height: 12.38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Spacer(flex: 40),
                        SizedBox(
                          width: 298.0,
                          height: 85.0,
                          child: Column(
                            children: <Widget>[
                              Spacer(flex: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Zdalne sterowanie',
                                  style: TextStyle(
                                    fontFamily: 'HK Grotesk',
                                    fontSize: 35.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    height: 0.97,
                                  ),
                                ),
                              ),
                              Text(
                                'Steruj osiami drukarki',
                                style: TextStyle(
                                  fontFamily: 'HK Grotesk',
                                  fontSize: 30.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  height: 1.13,
                                ),
                              ),
                              Spacer(flex: 10),
                            ],
                          ),
                        ),
                        Spacer(flex: 42),
                      ],
                    ),
                  ),
                ),
              ),
              Spacer(flex: 10),
            ],
          ),
        ),
      ),
    );
    return res;
  }
}
