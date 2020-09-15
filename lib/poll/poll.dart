import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:rxdart/rxdart.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:juneau/common/components/alertComponent.dart';

import 'package:juneau/common/methods/userMethods.dart';

Future<List> _getImages(List options) async {
  List imageBytes = [];
  for (var option in options) {
    String url = option['content'];
    var response = await http.get(url);
    if (response.statusCode == 200) {
      imageBytes.add(response.bodyBytes);
    }
  }
  return imageBytes;
}

Future<List> _getOptions(poll) async {
  const url = 'http://localhost:4000/option';

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');

  var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

  List optionIds = poll['options'];
  List<Future> futures = [];
  List options;

  for (var i = 0; i < optionIds.length; i++) {
    var optionId = optionIds[i];
    Future future() async {
      var response = await http.get(
        url + '/' + optionId,
        headers: headers,
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        return jsonResponse;
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    }

    futures.add(future());
  }

  await Future.wait(futures).then((results) {
    options = results;
  });

  return options;
}

class PollWidget extends StatefulWidget {
  final poll;
  final user;

  PollWidget({Key key, @required this.poll, this.user}) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  final streamController = StreamController();
  var user, poll, pollCreator;
  List options;
  List followingCategories;
  bool warning = false;

  @override
  void initState() {
    poll = widget.poll;
    user = widget.user;

    followingCategories = user['followingCategories'];

    userMethods.getUser(poll['createdBy']).then((pollUser) {
      if (pollUser != null && pollUser.length > 0) {
        pollCreator = pollUser[0];
      }
      _getOptions(poll).then((pollOptions) {
        if (mounted) {
          setState(() {
            if (pollOptions != null && pollOptions.length > 0) {
              options = pollOptions;
            }
          });
        }
      });
    });

    streamController.stream.throttleTime(Duration(milliseconds: 1000)).listen((category) {
      bool unfollow = false;
      if (followingCategories.contains(category)) {
        unfollow = true;
      }

      warning = true;
      Timer(Duration(milliseconds: 1000), () {
        warning = false;
      });

      followCategory(category, unfollow, context);
    });

    super.initState();
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  void followCategory(String category, bool unfollow, context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
    String userId = prefs.getString('userId');

    String url = 'http://localhost:4000/user/' + userId;

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token}, response, body;

    response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      user = jsonResponse[0];
      followingCategories = user['followingCategories'];

      if (!followingCategories.contains(category) || unfollow) {
        if (unfollow) {
          followingCategories.remove(category);
        } else {
          followingCategories.add(category);
        }

        body = jsonEncode({'followingCategories': followingCategories});
        response = await http.put(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          setState(() {});
        } else {
          return showAlert(context, 'Something went wrong, please try again');
        }
      } else {
        setState(() {});
      }
    } else {
      return showAlert(context, 'Something went wrong, please try again');
    }
  }

  @override
  void didUpdateWidget(covariant PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    userMethods.getUser(poll['createdBy']).then((pollUser) {
      if (pollUser != null && pollUser.length > 0) {
        pollCreator = pollUser[0];
      }
      _getOptions(poll).then((pollOptions) {
        if (mounted) {
          setState(() {
            if (pollOptions != null && pollOptions.length > 0) {
              options = pollOptions;
            }
          });
        }
      });
    });
  }

  void vote(option) async {
    String url = 'http://localhost:4000/option/vote/' + option['_id'].toString();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var response = await http.put(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body), updateOption = jsonResponse['option'];

      for (var i = 0; i < options.length; i++) {
        if (options[i]['_id'] == updateOption["_id"]) {
          options[i] = updateOption;
          break;
        }
      }

      updateUserCompletedPolls(poll['_id'], option['_id']);
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  void updateUserCompletedPolls(pollId, optionId) async {
    const url = 'http://localhost:4000/user/';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token'), userId = prefs.getString('userId');

    var headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: token};

    var response = await http.get(url + userId, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body)[0],
          completedPolls = jsonResponse['completedPolls'],
          selectedOptions = jsonResponse['selectedOptions'];

      completedPolls.add(pollId);
      selectedOptions.add(optionId);

      var body = jsonEncode({'completedPolls': completedPolls, 'selectedOptions': selectedOptions});

      response = await http.put(url + userId, headers: headers, body: body);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        user = jsonResponse['user'];

        if (mounted) {
          setState(() {});
        }
      }
      if (response.statusCode != 200) {
        print('Request failed with status: ${response.statusCode}.');
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  Widget buildPoll() {
    DateTime createdAt = DateTime.parse(poll['createdAt']);
    List pollCategories = poll['categories'];
    String time = timeago.format(createdAt, locale: 'en_short');
    List<Widget> children = [
      Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0, bottom: 3.0),
        child: Text(
          poll['prompt'],
          style: TextStyle(
            fontFamily: 'Lato Black',
            fontSize: 18.0,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 6.0),
        child: Row(
          children: <Widget>[
            GestureDetector(
                child: Text(
                  pollCreator['username'],
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 13.0,
                  ),
                ),
                onTap: () {
                  print(pollCreator['email']);
                }),
            Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Text(
                time,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                  wordSpacing: -4.0,
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 10.0),
        child: SizedBox(
          height: 32.0,
          child: new ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pollCategories.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Container(
                  decoration: new BoxDecoration(
                      color:
                          followingCategories.contains(pollCategories[index]) ? Theme.of(context).accentColor : Theme.of(context).highlightColor,
                      borderRadius: new BorderRadius.all(const Radius.circular(15.0))),
                  child: GestureDetector(
                    onTap: () {
                      if (warning) {
                        showAlert(context, "You're going that too fast. Take a break.");
                      }
                      streamController.add(pollCategories[index]);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Center(
                        child: Text(
                          pollCategories[index],
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];

    if (options.length > 0) {
      var completedPolls = user['completedPolls'];

      bool completed = completedPolls.indexOf(poll['_id']) >= 0;
      int totalVotes = 0;
      int highestVote = 0;

      if (completed) {
        for (var c in options) {
          int votes = c['votes'];
          totalVotes += votes;
          if (votes > highestVote) {
            highestVote = votes;
          }
        }
      }

      double screenWidth = MediaQuery.of(context).size.width;
      int optionsLength = options.length;
      bool lengthGreaterThanFour = optionsLength > 4;
      double divider = lengthGreaterThanFour ? 3 : 2;
      double size = screenWidth / divider;
      double containerHeight;

      if (lengthGreaterThanFour) {
        containerHeight = optionsLength > 6 ? size * 3 : size * 2;
      } else {
        containerHeight = optionsLength > 2 ? size * 2 : size;
      }

      children.add(FutureBuilder<List>(
          future: _getImages(options),
          builder: (context, AsyncSnapshot<List> imageBytes) {
            if (imageBytes.hasData) {
              List imageBytesList = imageBytes.data;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.75),
                child: Container(
                  height: containerHeight,
                  child: GridView.count(
                      physics: new NeverScrollableScrollPhysics(),
                      crossAxisCount: lengthGreaterThanFour ? 3 : 2,
                      children: List.generate(optionsLength, (index) {
                        var option = options[index];
                        int votes = option['votes'];
                        double percent = votes > 0 ? votes / totalVotes : 0;
                        String percentStr = (percent * 100.0).toStringAsFixed(0) + '%';

                        Image image = Image.memory(imageBytesList[index]);

                        return Padding(
                          padding: const EdgeInsets.all(0.75),
                          child: GestureDetector(
                            onDoubleTap: () {
                              if (!completed) {
                                HapticFeedback.mediumImpact();
                                vote(options[index]);
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  child: image,
                                  width: size,
                                  height: size,
                                ),
                                completed
                                    ? Stack(children: [
                                        Opacity(
                                          opacity: 0.3,
                                          child: Container(
                                            decoration: new BoxDecoration(
                                              color: Theme.of(context).backgroundColor,
                                            ),
                                            width: size,
                                            height: size,
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            percentStr,
                                            style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w600,
                                                color: highestVote == votes ? Colors.white : Colors.white54),
                                          ),
                                        ),
                                      ])
                                    : Container(),
                              ],
                            ),
                          ),
                        );
                      })),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.75),
                child: new Container(
                    height: containerHeight,
                    child: GridView.count(
                        physics: new NeverScrollableScrollPhysics(),
                        crossAxisCount: lengthGreaterThanFour ? 3 : 2,
                        children: List.generate(optionsLength, (index) {
                          return Padding(
                            padding: const EdgeInsets.all(0.75),
                            child: Container(width: size, height: size, color: Theme.of(context).highlightColor),
                          );
                        }))),
              );
            }
          }));

      children.add(Padding(
        padding: const EdgeInsets.only(left: 10.0, top: 10.0),
        child: Text(
          totalVotes == 1 ? '$totalVotes vote' : '$totalVotes votes',
          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Theme.of(context).hintColor),
        ),
      ));

      children.add(SizedBox(height: 10.0));
    }

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (options == null) {
      return new Container();
    }
    return buildPoll();
  }
}
