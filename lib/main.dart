import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_upload_example/api/firebase_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final String title = 'Firebase Upload';

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: title,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: MainPage(),
      );
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Stream<QuerySnapshot> _stream;
  UploadTask? task;
  File? file;
  String filePath = "";
  late String destination;
  List datas = [];
  void getUrl() async {
    final storageRef = FirebaseStorage.instance.ref().child("files");

    final listResult = await storageRef.listAll();
    for (var prefix in listResult.prefixes) {
      // pri
    }
    for (var item in listResult.items) {
      print(item);
      return datas.add(item);
      // The items under storageRef.
    }
  }

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance.collection("Kumaresan").snapshots();
    getUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(MyApp.title),
          centerTitle: true,
        ),
        body: Container(
          padding: EdgeInsets.all(32),
          child: StreamBuilder<Object>(
              stream: _stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                ;
                return ListView.builder(
                    itemCount: (snapshot.data as QuerySnapshot).docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> document =
                          (snapshot.data as QuerySnapshot).docs[index].data()
                              as Map<String, dynamic>;

                      return VideoPlayerClass(
                        document["image_url"].toString(),
                        document["file_name"].toString(),
                      );
                    });
              }),
        ),
        floatingActionButton:
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FloatingActionButton(
            onPressed: () => {},
            child: task != null ? buildUploadStatus(task!) : Text("0.0 %"),
          ),
          SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              selectFile();
            },
            child: Icon(Icons.add),
            heroTag: "fab1",
          ),
        ]));
  }

  Future selectFile() async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.video);
    if (result == null) return;
    final path = result.files.single.path!;

    setState(() {
      file = File(path);
    });
    uploadFile();
  }

  Future uploadFile() async {
    if (file == null) return;

    filePath = basename(file!.path);

    final destination = 'files/$filePath';

    task = FirebaseApi.uploadFile(destination, file!);
    setState(() {});

    if (task == null) return;

    final snapshot = await task!.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();
    FirebaseFirestore.instance.collection("Kumaresan").add({
      "image_url": urlDownload,
      "file_name": filePath.toString().substring(0, 20)
    });
    print('Download-Link: $urlDownload');
  }

  Widget buildUploadStatus(UploadTask task) => StreamBuilder<TaskSnapshot>(
        stream: task.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final snap = snapshot.data!;
            final progress = snap.bytesTransferred / snap.totalBytes;
            final percentage = (progress * 100).toString().substring(0, 3);

            return Center(
              child: Text(
                '$percentage %',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            );
          } else {
            return Container();
          }
        },
      );

  getTemporaryDirectory() {}
}

class VideoPlayerClass extends StatefulWidget {
  String videoUrl;
  late String filePath;

  VideoPlayerClass(
    this.videoUrl,
    this.filePath,
  );

  @override
  State<VideoPlayerClass> createState() => _VideoPlayerClassState();
}

class _VideoPlayerClassState extends State<VideoPlayerClass> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Container(
        height: 230,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 10),
              height: 200,
              width: 300,
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : Container(),
            ),
            Text(
              widget.filePath,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
