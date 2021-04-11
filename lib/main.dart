import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rtmp_publisher/camera.dart';
import 'package:video_player/video_player.dart';

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(),
        '/player': (context) => VideoPlayerPage(),
        '/broadcast': (context) => BroadCastPage(),
      },
    );
  }
}

class VideoPlayerPage extends StatefulWidget {

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}


class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    _controller = VideoPlayerController.network('http://101.101.209.23/hls/1234.m3u8');
    _initializeVideoPlayerFuture = _controller.initialize();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Player"),
      ),
      body: Center(
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              );
            } else {
              return Center(child: CircularProgressIndicator(),);
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
            _controller.value.isPlaying ? Icons.pause: Icons.play_arrow
        ),
      ),
    );
  }
}

class BroadCastPage extends StatefulWidget {

  @override
  _BroadCastPageState createState() => _BroadCastPageState();
}

class _BroadCastPageState extends State<BroadCastPage> with WidgetsBindingObserver {
  CameraController controller;
  List<CameraDescription> cameras;
  String url = "rtmp://101.101.209.23:1935/live";
  Timer _timer;

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> initCamera() async {

    WidgetsFlutterBinding.ensureInitialized();

    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<String> startVideoStreaming() async {
    if (!controller.value.isInitialized) {
      print('Error: select a camera first.');
      return null;
    }

    if (controller.value.isStreamingVideoRtmp) {
      return null;
    }

    // Open up a dialog for the url
    String myUrl = await url;

    try {
      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
      url = myUrl;
      await controller.startVideoStreaming(url);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if(controller != null && controller.value.isStreamingVideoRtmp) {
          var stats = await controller.getStreamStatistics();
          print(stats);
        }
      });
    } on CameraException catch (e) {
      print(e);
      return null;
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera example'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? controller.value.isStreamingVideoRtmp
                      ? Colors.redAccent
                      : Colors.orangeAccent
                      : controller != null &&
                      controller.value.isStreamingVideoRtmp
                      ? Colors.blueAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          startVideoStreaming();
        },
      ),
    );
  }
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            OutlinedButton(
              child: Text("방송보기"),
              onPressed: () {
                print("방송보기");
                Navigator.pushNamed(context, '/player');
              },
            ),
            OutlinedButton(
              child: Text("방송하기"),
              onPressed: () {
                print("방송하기");
                Navigator.pushNamed(context, '/broadcast');
              },
            ),
          ],
        ),
      ),
    );
  }
}