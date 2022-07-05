import 'package:flutter/material.dart';

void main() {
  runApp(new MaterialApp(
    home: new Utils(),
  ));
}

class Utils extends StatefulWidget {
  @override
  _AppState createState() => _AppState();

  void onLoading(BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
              child: CircularProgressIndicator(
            color: Colors.blue,
          ));
        });
  }

  void prints(var s1) {
    String s = s1.toString();
    debugPrint(" =======> " + s.toString(), wrapWidth: 1024);
  }
}

class _AppState extends State<Utils> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("data"),
      ),
      body: Container(
        child: new Text("flutter"),
      ),
    );
  }
}
