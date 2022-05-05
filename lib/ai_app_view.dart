import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:section6/ai_app_controller.dart';

class MyAIApp extends StatelessWidget {
  const MyAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SMILE SNS",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainForm(),
    );
  }
}

class MainForm extends HookConsumerWidget {
  const MainForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(aiAppViewModel);
    return Scaffold(
        appBar: AppBar(
          title: const Text("SMILE SNS"),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Padding(padding: EdgeInsets.all(30.0)),
            Text(controller.processingMessage,
                style: const TextStyle(
                  color: Colors.lightBlue,
                  fontSize: 32.0,
                )),
            TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.person),
                hintText: "Please input your name.",
                labelText: "YOUR NAME",
              ),
              onChanged: (text) {
                controller.setName(text);
              },
            )
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () {
                controller.getImageAndFindFace(context, ImageSource.gallery);
              },
              tooltip: "Select Image",
              heroTag: "gallery",
              child: const Icon(Icons.add_photo_alternate),
            ),
            const Padding(padding: EdgeInsets.all(10.0)),
            FloatingActionButton(
              onPressed: () {
                controller.getImageAndFindFace(context, ImageSource.camera);
              },
              tooltip: "Take Photo",
              heroTag: "camera",
              child: const Icon(Icons.add_a_photo),
            ),
          ],
        ));
  }
}

class TimelinePage extends StatelessWidget {
  const TimelinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("SMILE SNS"),
        ),
        body: Container(
          child: _buildBody(context),
        ));
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("smiles")
          .orderBy("date", descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return _buildList(context, snapshot.data!.docs);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapList) {
    return ListView.builder(
        padding: const EdgeInsets.all(18.0),
        itemCount: snapList.length,
        itemBuilder: (context, i) {
          return _buildListItem(context, snapList[i]);
        });
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot snap) {
    final Map<String, dynamic> _data = snap.data()! as Map<String, dynamic>;
    DateTime _datetime = _data["date"].toDate();
    var _formatter = DateFormat("MM/dd HH:mm");
    String postDate = _formatter.format(_datetime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 9.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListTile(
          leading: Text(postDate),
          title: Text(_data["name"]),
          subtitle: Text("は" +
              (_data["smile_prob"] * 100.0).toStringAsFixed(1) +
              "%の笑顔です。"),
          trailing: Text(
            _getIcon(_data["smile_prob"]),
            style: const TextStyle(
              fontSize: 24,
            ),
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePage(_data["image_url"]),
                ));
          },
        ),
      ),
    );
  }

  String _getIcon(double smileProb) {
    String icon = "";
    if (smileProb < 0.2) {
      icon = "😧";
    } else if (smileProb < 0.4) {
      icon = "😌";
    } else if (smileProb < 0.6) {
      icon = "😀";
    } else if (smileProb < 0.8) {
      icon = "😄";
    } else {
      icon = "😆";
    }
    return icon;
  }
}

class ImagePage extends StatelessWidget {
  String _imageUrl = "";

  ImagePage(String imageUrl) {
    this._imageUrl = imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMILE SNS"),
      ),
      body: Center(
        child: Image.network(_imageUrl),
      ),
    );
  }
}
