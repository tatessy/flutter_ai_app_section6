import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:section6/ai_app_view.dart';
import 'package:uuid/uuid.dart';

final aiAppViewModel = ChangeNotifierProvider((_) => AiAppViewModel());

class AiAppViewModel extends ChangeNotifier {
  String name = "";
  String processingMessage = "";
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(enableLandmarks: true, enableClassification: true));
  final ImagePicker picker = ImagePicker();

  //名前を入力
  void setName(String text) {
    name = text;
    notifyListeners();
  }

//イメージを取得して、顔を検出する
  void getImageAndFindFace(
      BuildContext context, ImageSource imageSource) async {
    processingMessage = "Processing...";
    notifyListeners();

    final XFile? pickedImage = await picker.pickImage(source: imageSource);
    final File imageFile = File(pickedImage!.path);
    final InputImage visionImage = InputImage.fromFile(imageFile);

    List<Face> faces = await faceDetector.processImage(visionImage);
    if (faces.length > 0) {
      String imagePath =
          "/images/" + const Uuid().v1() + basename(pickedImage.path);
      Reference ref = FirebaseStorage.instance.ref().child(imagePath);
      final TaskSnapshot storedImage = await ref.putFile(imageFile);

      final String downloadUrl = await storedImage.ref.getDownloadURL();
      Face largestFace = findLargestFace(faces);

      FirebaseFirestore.instance.collection("smiles").add({
        "name": name,
        "smile_prob": largestFace.smilingProbability,
        "image_url": downloadUrl,
        "date": Timestamp.now(),
      });
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TimelinePage(),
          ));
    }

    processingMessage = "";
    notifyListeners();
  }

//大きい顔の検出
  Face findLargestFace(List<Face> faces) {
    Face largestFace = faces[0];
    for (Face face in faces) {
      if (face.boundingBox.height + face.boundingBox.width >
          largestFace.boundingBox.height + largestFace.boundingBox.width) {
        largestFace = face;
      }
    }
    return largestFace;
  }
}
