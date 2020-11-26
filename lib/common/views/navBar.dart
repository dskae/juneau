import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/poll/pollCreate.dart';

void logout(context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs?.clear();
  Navigator.of(context).pushNamedAndRemoveUntil('/loginSelect', (Route<dynamic> route) => false);
}

class NavBar extends StatefulWidget {
  final navigatorKey;
  final navController;

  NavBar({Key key,
    @required this.navigatorKey,
    this.navController,
  })
    : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _previousIndex = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82.0,
      child: BottomNavigationBar(
        elevation: 0.0,
        backgroundColor: Theme
          .of(context)
          .backgroundColor,
        unselectedItemColor: Theme
          .of(context)
          .buttonColor,
        selectedItemColor: Theme
          .of(context)
          .accentColor,
        selectedFontSize: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
            switch (index) {
              case 0:
                _previousIndex = _selectedIndex;
                widget.navController.add(0);
                break;

              case 1:
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) {
                    return new PollCreate();
                  });
                _selectedIndex = _previousIndex;
                break;

              case 2:
                _previousIndex = _selectedIndex;
                widget.navController.add(1);
                break;

              default:
                break;
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.home_outlined,
              size: 28.0
            ),
            activeIcon: new Icon(
              Icons.home,
              size: 28.0
            ),
            title: Text(''),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.add_circle_outline,
              size: 28.0
            ),
            title: Text(''),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.account_circle_outlined,
              size: 28.0
            ),
            activeIcon: new Icon(
              Icons.account_circle,
              size: 28.0
            ),
            title: Text(''),
          ),
        ],
      ),
    );
  }
}
