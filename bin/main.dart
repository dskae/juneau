import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/common/views/appBar.dart';
import 'package:juneau/common/views/navBar.dart';

import 'package:juneau/auth/loginSelect.dart';
import 'package:juneau/auth/login.dart';
import 'package:juneau/auth/signUpSelect.dart';
import 'package:juneau/auth/signUp.dart';
import 'package:juneau/home/home.dart';
import 'package:juneau/profile/profile.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    Color black = const Color(0xFF020202);

    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        backgroundColor: const Color(0xFFFEFEFE),
        hintColor: const Color(0xFF9c9e9f),
        highlightColor: Colors.blue,
        accentColor: const Color(0xFFef3b4a),
        buttonColor: black,
        textTheme: TextTheme(
          headline1: TextStyle(color: black),
          headline6: TextStyle(color: black),
          bodyText2: TextStyle(color: black),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (BuildContext context) => SplashScreen(),
        '/main': (BuildContext context) => MainScaffold(),
        '/loginSelect': (BuildContext context) => LoginSelectPage(),
        '/login': (BuildContext context) => LoginPage(),
        '/signUpSelect': (BuildContext context) => SignUpSelectPage(),
        '/signUp': (BuildContext context) => SignUpPage(),
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final PageController _pageController = PageController();
  final StreamController _navController = StreamController();
  var appBar, navBar, homePage, profilePage;

  @override
  void initState() {
    appBar = ApplicationBar(height: 0.0);
    navBar = NavBar(navigatorKey: _navigatorKey, navController: _navController);
    homePage = HomePage();
    profilePage = ProfilePage();

    _navController.stream.listen((index) async {
      _pageController.jumpToPage(index);
    });

    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: appBar,
      body: PageView(
        physics:new NeverScrollableScrollPhysics(),
        children:[
          homePage,
          profilePage,
        ],
        controller: _pageController,
      ),
      bottomNavigationBar: navBar,
    );
  }
}


class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Container(
          width: 300.0,
          height: 300.0,
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("images/cubesmelt.gif"), fit: BoxFit.fitWidth),
          ),
        ),
      ),
    );
  }

  void startTimer() {
    Timer(Duration(seconds: 3), () {
      navigateUser();
    });
  }

  void navigateUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool('isLoggedIn') ?? false;
    if (status) {
      Navigator.pushNamed(context, '/main');
    } else {
      Navigator.pushNamed(context, '/signUpSelect');
    }
  }
}
