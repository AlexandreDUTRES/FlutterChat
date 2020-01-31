import 'package:flutter/material.dart';
import 'package:chat/Event.dart';
import 'package:chat/Socket.dart';
import 'package:chat/ConnectionPage.dart';

enum InfoType { typing, joined, left }

class ChatPage extends StatefulWidget {
  ChatPage({@required this.userName, @required this.userNumber});

  final String userName;
  final int userNumber;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Socket _socket = Socket.instance;
  Event _event = Event.instance;

  double widthScreen;
  double heightScreen;

  double topChatHeight = 30;
  double bottomChatHeight = 70;

  List<Widget> _listMessages = [];
  int _currentUserNumber;

  String _userTyping = "";

  ScrollController _scrollController = new ScrollController();
  TextEditingController _inputMessageController = new TextEditingController();

  void computeEvent(GlobalEvent event) {
    setState(() {
      switch (event.flag) {
        case EventFlag.socketUserJoined:
          _currentUserNumber = event.value['numUsers'];
          _listMessages
              .add(buildInformation(InfoType.joined, event.value['username']));
          break;
        case EventFlag.socketUserLeft:
          _currentUserNumber = event.value['numUsers'];
          _listMessages
              .add(buildInformation(InfoType.left, event.value['username']));
          break;
        case EventFlag.socketNewMessage:
          _listMessages.add(buildMessage(event.value));
          break;
        case EventFlag.socketTyping:
          _userTyping = event.value['username'];
          break;
        case EventFlag.socketStopTyping:
          _userTyping = "";
          break;
        case EventFlag.socketError:
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ConnectionPage(showError: true),
              ));
          break;
        default:
      }
    });

    scrollBottom();
  }

  void scrollBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    _currentUserNumber = widget.userNumber;

    _inputMessageController.addListener((){
      if (_inputMessageController.text.length > 1) {
        _socket.beginTyping();
        Future.delayed(const Duration(milliseconds: 500), () {
          _socket.stopTyping();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _event.getBus().on<GlobalEvent>().listen(computeEvent);
    });
  }

  Widget buildMessage(data) {
    return Container(
      margin: EdgeInsets.only(bottom: widthScreen * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(left: widthScreen * 0.015, bottom: 2),
            child:
                Text(data['username'], style: TextStyle(color: Colors.black)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
            padding: EdgeInsets.symmetric(
              vertical: widthScreen * 0.02,
              horizontal: widthScreen * 0.04,
            ),
            child: Text(
              data['message'],
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInformation(InfoType type, String username) {
    String text;

    switch (type) {
      case InfoType.typing:
        text = username + " est entrain d'écrire...";
        break;
      case InfoType.joined:
        text = username + " a rejoint";
        break;
      case InfoType.left:
        text = username + " a quitté";
        break;
    }

    return Container(
      alignment:
          type == InfoType.typing ? Alignment.centerLeft : Alignment.center,
      width: widthScreen,
      margin: EdgeInsets.only(bottom: widthScreen * 0.02),
      child: Text(
        text,
        style: TextStyle(
          color: type == InfoType.typing ? Colors.grey : Colors.black,
        ),
      ),
    );
  }

  Widget buildBottomChat() {
    return Container(
      height: bottomChatHeight,
      padding: EdgeInsets.symmetric(horizontal: widthScreen * 0.02),
      color: Colors.grey[300],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: TextField(
              controller: _inputMessageController,
              maxLines: 1,
              maxLength: 50,
            ),
          ),
          IconButton(
              iconSize: 30,
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                String text = _inputMessageController.text;
                if (text.length > 1) {
                  setState(() {
                    _listMessages.add(buildMessage(
                        {"username": widget.userName, "message": text}));
                  });
                  _socket.sendMessage(text);
                  _inputMessageController.clear();
                  FocusScope.of(context).requestFocus(new FocusNode());

                  scrollBottom();
                }
              }),
        ],
      ),
    );
  }

  Widget buildChat() {
    List<Widget> body = [];
    body.addAll(_listMessages);

    if (_userTyping.length > 1) {
      body.add(buildInformation(InfoType.typing, _userTyping));
    }

    return Container(
      width: widthScreen,
      height: heightScreen,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: bottomChatHeight,
              top: topChatHeight,
              right: widthScreen * 0.04,
              left: widthScreen * 0.04,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: body,
              ),
            ),
          ),
          Positioned(
            width: widthScreen,
            top: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: widthScreen * 0.04),
              color: Colors.green,
              height: topChatHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Connecté : " + widget.userName,
                      style: TextStyle(color: Colors.white)),
                  Text(_currentUserNumber.toString(),
                      style: TextStyle(color: Colors.white))
                ],
              ),
            ),
          ),
          Positioned(width: widthScreen, bottom: 0, child: buildBottomChat())
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    widthScreen = MediaQuery.of(context).size.width;
    heightScreen = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Real Time Chat'),
      ),
      body: buildChat(),
    );
  }
}
