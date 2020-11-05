import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juneau/poll/pollCreate.dart';

void logout(context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs?.clear();
  Navigator.of(context).pushNamedAndRemoveUntil('/loginSelect', (Route<dynamic> route) => false);
}

Widget navBar() {
  return NavBar();
}

class NavBar extends StatefulWidget {
  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BottomNavigationBar(
        elevation: 0.0,
        backgroundColor: Theme.of(context).backgroundColor,
        unselectedItemColor: Theme.of(context).buttonColor,
        selectedItemColor: Theme.of(context).accentColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
            switch (index) {
              case 0:
                logout(context);
                break;
              case 1:
                showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext context) {
                      return new PollCreate();
                    });
                break;
              default:
                break;
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.home,
              size: 28.0
            ),
            title: Text(''),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.add,
              size: 28.0
            ),
            title: Text(''),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
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
