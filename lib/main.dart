import 'package:flutter/material.dart';

// dependencies
import 'package:flutter_ion/flutter_ion.dart';
import 'package:flutter_webrtc/webrtc.dart';

// local
import 'package:conference/video_render_adapter.dart';

void main() {
  runApp(ConferenceApp());
}

class ConferenceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ConferenceWelcomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class ConferenceWelcomePage extends StatefulWidget {
  ConferenceWelcomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ConferenceWelcomePageState createState() => _ConferenceWelcomePageState();
}

class _ConferenceWelcomePageState extends State<ConferenceWelcomePage> {
  Client client;
  String rid = "room1";
  List<VideoRendererAdapter> _remoteVideos = List();
  VideoRendererAdapter _localVideo;

  bool _cameraOff = false;
  bool _microphoneOff = false;
  bool _speakerOn = true;
  var _scaffoldkey = GlobalKey<ScaffoldState>();
  var _messages = [];
  var name;
  var room;

  final double LOCAL_VIDEO_WIDTH = 114.0;
  final double LOCAL_VIDEO_HEIGHT = 72.0;

  @override
  initState() {
    super.initState();
    init();
  }

  @override
  void dispose() async {
    await client.leave();
    await client.close();

    super.dispose();
  }

  void init() async {
    var url = 'https://192.168.0.14:8443/ws';

    this.client = Client(url);

    await client.connect();

    client.on('peer-join', (rid, id, info) async {
      print("on peer join");
    });

    client.on('peer-leave', (rid, id) async {
      print("on peer leave");
    });

    client.on('transport-open', () {
      print("on transport open");
    });

    client.on('transport-closed', () {
      print("on transport close");
    });

    client.on('stream-add', (rid, mid, info, tracks) async {
      var bandwidth = '512';
      var stream = await client.subscribe(rid, mid, tracks, bandwidth);
      var adapter = VideoRendererAdapter(stream.mid, stream, false, mid);
      await adapter.setupSrcObject();
      this.setState(() {
        _remoteVideos.add(adapter);
      });
      print(":::stream-add [$mid]:::");
    });

    client.on('stream-remove', (rid, mid) async {
      var adapter = _remoteVideos.firstWhere((item) => item.sid == mid);
      if (adapter != null) {
        await adapter.dispose();
        this.setState(() {
          _remoteVideos.remove(adapter);
        });
      }
      print(":::stream-remove [$mid]:::");
      print("on stream remove");
    });

    client.on('broadcast', (rid, uid, info) async {
      print("on broadcast");
    });

    await client.join(rid, {'name': 'Andrey'});

    try {
      // Publish local stream
      var resolution = 'vga';
      var bandwidth = '512';
      var codec = 'vp8';
      var localStream = await client
          .publish(true, true, false, codec, bandwidth, resolution)
          .then((stream) async {
        var adapter = VideoRendererAdapter(stream.mid, stream, true);
        await adapter.setupSrcObject();
        var localStream = stream.stream;
        MediaStreamTrack audioTrack = localStream.getAudioTracks()[0];
        audioTrack.enableSpeakerphone(true);
        this.setState(() {
          _localVideo = adapter;
        });
      });
    } catch (err) {}

    //client.broadcast(rid, {'name': 'Andrey'});
  }

  //Switch local camera
  _switchCamera() {
    if (_localVideo != null && _localVideo.stream.getVideoTracks().length > 0) {
      _localVideo.stream.getVideoTracks()[0].switchCamera();
    } else {
      print(":::Unable to switch the camera:::");
    }
  }

  Widget _buildMainVideo() {
    if (_remoteVideos.length == 0)
      return Image.asset(
        'assets/images/loading.jpeg',
        fit: BoxFit.cover,
      );

    var adapter = _remoteVideos[0];
    return GestureDetector(
        onDoubleTap: () {
          adapter.switchObjFit();
        },
        child: RTCVideoView(adapter.renderer));
  }

  Widget _buildLocalVideo(Orientation orientation) {
    if (_localVideo != null) {
      return SizedBox(
          width: (orientation == Orientation.portrait)
              ? LOCAL_VIDEO_HEIGHT
              : LOCAL_VIDEO_WIDTH,
          height: (orientation == Orientation.portrait)
              ? LOCAL_VIDEO_WIDTH
              : LOCAL_VIDEO_HEIGHT,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(
                color: Colors.white,
                width: 0.5,
              ),
            ),
            child: GestureDetector(
                onTap: () {
                  _switchCamera();
                },
                onDoubleTap: () {
                  _localVideo.switchObjFit();
                },
                child: RTCVideoView(_localVideo.renderer)),
          ));
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return SafeArea(
        child: Scaffold(
          key: _scaffoldkey,
          body: orientation == Orientation.portrait
              ? Container(
            color: Colors.black87,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black54,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            child: _buildMainVideo(),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 48,
                          child: Container(
                            child: _buildLocalVideo(orientation),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 48,
                  child: Stack(
                    children: <Widget>[
                      Opacity(
                        opacity: 0.5,
                        child: Container(
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(0.0),
                        child: Center(
                          child: Text(
                            'Ion Flutter Demo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              : Container(
            color: Colors.black54,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black87,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            child: _buildMainVideo(),
                          ),
                        ),
                        Positioned(
                          right: 60,
                          top: 10,
                          child: Container(
                            child: _buildLocalVideo(orientation),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
