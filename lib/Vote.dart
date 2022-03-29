import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropdown_alert/alert_controller.dart';
import 'package:flutter_dropdown_alert/model/data_alert.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'HomePage.dart';
import 'package:simple_polls/simple_polls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
class Vote extends StatefulWidget {
  const Vote({Key? key}) : super(key: key);

  @override
  _VoteState createState() => _VoteState();
}

var call;
var foot;
var nowdate;
var nowdat;
var now;
var tomorrow;
var content;
var _future;
var userid;
var sharedPreferences;
var token;
var _hasVoted;
var _voteCall;
var _voteFoot;
class _VoteState extends State<Vote> {
  Future<void> getUserData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    userid = sharedPreferences.getInt('userID');
    token = sharedPreferences.getString('token');
  }

  Future<Map> showVote() async {
    var response = await http
        .get(Uri.http("13.209.87.55", "api/v1/Vote", {"pub_date": "$nowdat"}),
      headers: {
        "Authorization": "Token ${token}",
        "Content-Type": "application/json"
      },);

    if (response.statusCode == 200) {
      // 만약 서버가 OK 응답을 반환하면, JSON을 파싱합니다.
      content = jsonDecode(utf8.decode(response.bodyBytes));
      if (content[0]['call'].contains(userid)) {
        _hasVoted = true;
        _voteCall = true;
        _voteFoot = false;
        print('1'+ _hasVoted.toString());

      }
      else if (content[0]['foot'].contains(userid)) {
        _hasVoted = true;
        _voteCall = false;
        _voteFoot = true;
      }
      else{
        _hasVoted = false;
        _voteCall=false;
        _voteFoot=false;
      }



      content[0]['userid'] = sharedPreferences.getInt("userID");
      content[0]['callCount'] = content[0]['call'].length;
      content[0]['footCount'] = content[0]['foot'].length;


      return content[0];
    } else {
      // 만약 응답이 OK가 아니면, 에러를 던집니다.
      throw Exception('Failed to load post');
    }
  }

  Future<void> voteCall(int id) async {
    final responsedata = await http.get(
      Uri.http('13.209.87.55', 'api/v1/Vote/$id/'),
      headers: {
        "Authorization": "Token ${token}",
        "Content-Type": "application/json"
      },
    );
    final data = jsonDecode(utf8.decode(responsedata.bodyBytes));
    final imsi = data['call'];
    data['call'] = imsi + [userid];
    print(data);
    final responsecall =await http.patch(Uri.http('13.209.87.55', "api/v1/Vote/$id/"),
        headers: {
          "Authorization": "Token ${token}",
          "Content-Type": "application/json"
        },
        body: jsonEncode(
          {
            'pub_date' : nowdat,
            'call': data['call'],
            'foot' : data['foot']
          }
        ));
    print(responsecall.body);
    _voteCall= true;
    _hasVoted=true;
  }
  Future<void> voteFoot(int id) async {
    final responsedata = await http.get(
      Uri.http('13.209.87.55', 'api/v1/Vote/$id/'),
      headers: {
        "Authorization": "Token ${token}",
        "Content-Type": "application/json"
      },
    );
    final data = jsonDecode(utf8.decode(responsedata.bodyBytes));
    final imsi = data['foot'];
    data['foot'] = imsi + [userid];
    print(data);
    final responsefoot =await http.patch(Uri.http('13.209.87.55', "api/v1/Vote/$id/"),
        headers: {
          "Authorization": "Token ${token}",
          "Content-Type": "application/json"
        },
        body: jsonEncode(
            {
              'pub_date' : nowdat,
              'call': data['call'],
              'foot' : data['foot']
            }
        ));
    print(responsefoot.body);
    _voteFoot= true;
    _hasVoted=true;
  }
  Future<void> voteReset(int id) async {
    final responsedata = await http.get(
      Uri.http('13.209.87.55', 'api/v1/Vote/$id/'),
      headers: {
        "Authorization": "Token ${token}",
        "Content-Type": "application/json"
      },
    );
    final data = jsonDecode(utf8.decode(responsedata.bodyBytes));
    data['foot'].remove(userid);

    data['call'].remove(userid);

    final responsefoot =await http.patch(Uri.http('13.209.87.55', "api/v1/Vote/$id/"),
        headers: {
          "Authorization": "Token ${token}",
          "Content-Type": "application/json"
        },
        body: jsonEncode(
            {
              'pub_date' : nowdat,
              'call': data['call'],
              'foot' : data['foot']
            }
        ));
    _voteCall=false;
    _voteFoot=false;
    _hasVoted=false;
    print(responsefoot.body);
  }

  @override
  void initState() {

    super.initState();

    getUserData();
    showVote();
    _future = showVote();
    now = DateTime.now().toUtc();
    now=now.add(Duration(hours:9));


    String formattedDate = DateFormat('kk').format(now);

    if (int.parse(formattedDate) >9 ) {

      if (now.weekday == 5) {
        tomorrow =now.add(Duration(days:3)).toString();
      }
      else if (now.weekday == 6) {
        tomorrow = now.add(Duration(days: 2)).toString();
      }
      else {
        tomorrow = now.add(Duration(days: 1)).toString();
      }
      nowdat = tomorrow.substring(2, 10);
    }
    else {
      if (now.weekday==6) {
        nowdate = now.add(Duration(days: 2)).toString();
      }
      else if (now.weekday==7) {
        nowdate = now.add(Duration(days: 1)).toString();
      }
      else {
        nowdate = now.toString();

        nowdat = nowdate.substring(2, 10);
      }
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(122, 154, 130, 1),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('상승vs하락 투표', style: TextStyle(color: Colors.white),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Center(
                child: Column(
              children: [
                Container(
                    child: Text(
                  '20' + nowdat,
                  style: TextStyle(fontSize: 30, fontFamily: 'Strong'),
                )),
                Container(
                  child: Text(
                    '상승일까 하락일까?',
                    style: TextStyle(fontSize: 20, fontFamily: 'Nanum'),
                  ),
                )
              ],
            )),
            Container(
              child: FutureBuilder(
                  future: _future,
                  builder: (context, snapshot) {
                    

                    if (snapshot.hasError)
                      return Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Center(child: Text('로그인이 필요한 기능입니다')),
                      );
                    else if (!snapshot.hasData)
                      return Center(
                          child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.amber),
                      ));
                    else {
                      final restaurant = snapshot.data as Map;

                      return SimplePollsWidget(
                        /// onSelection will be triggered when users presses a option or presses undo button(only available on editable polls).
                        /// This function will be called after all the calculation like reducing total polls and marking previous option not selected.
                        /// It returns the PollFrameModel .Use this function to do some extra operations like storing this poll into other variable.
                        onSelection: (PollFrameModel model,
                            PollOptions? selectedOptionModel) {
                          print('Now total polls are : ' +
                              model.totalPolls.toString());
                          print('Selected option has label : ' +
                              selectedOptionModel!.label);
                          if (selectedOptionModel.id == 1) {
                            voteCall(restaurant['id']);
                          }
                          if (selectedOptionModel.id ==2) {
                            voteFoot(restaurant['id']);
                          }
                        },
                        onReset: (PollFrameModel model) {
                          print(
                              'Poll has been reset, this happens only in case of editable polls');
                          voteReset(restaurant['id']);

                        },
                        optionsBorderShape: RoundedRectangleBorder(),
                        // Default is stadium border

                        /// optionsStyle will have style used in options.
                        optionsStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),

                        /// languageCode will be used to translate some text used in status like total polls, Poll end time, Undo button.
                        /// Allowed values are it,fr,es,gr,en where en is default.
                        /// For more language support add translations for that language code in translations/translations.dart and widgets/poll_status.dart.
                        /// Add timeago.setLocaleMessages('it', timeago.ItMessages()); to register locales for timeago/remaining in widgets/poll_status.dart.
                        /// Add 'es': 'deshacer' to maps present in translations/translations.dart for other translations.
                        languageCode: 'ko',

                        /// Content Padding inside polls widget.
                        padding: EdgeInsets.all(15),

                        /// Margin for polls widget.
                        margin: EdgeInsets.all(15),

                        /// Data to be passed to polls widget.
                        model: PollFrameModel(
                          /// Title of the widget.
                          title: Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '다음 장이 상승일지 하락일지 예측보세요!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          totalPolls:
                              restaurant['footCount'] + restaurant['callCount'],

                          /// Poll end time
                          endTime:
                              DateTime.now().toUtc().add(Duration(days: 130)),

                          /// If user hasVoted then results screen will show up.
                          hasVoted: _hasVoted,
                          /// If poll is editable then undo button will appear in results screen to participate in poll again.
                          editablePoll: true,
                          options: <PollOptions>[
                            /// Configure options here
                            PollOptions(
                              label: "상승",
                              pollsCount: restaurant['callCount'],

                              /// Polls received by that option.
                              isSelected: _voteCall,

                              /// If poll selected.
                              id: 1,

                              /// Option id.
                            ),
                            PollOptions(
                              label: "하락",
                              pollsCount: restaurant['footCount'],
                              isSelected: _voteFoot,
                              id: 2,
                            ),
                          ],
                        ),
                      );
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
