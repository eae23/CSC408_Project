import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

class AddNewAttraction extends StatefulWidget
{
  const AddNewAttraction({super.key});

  @override
  State<AddNewAttraction> createState() => _AddNewAttractionState();
}

class _AddNewAttractionState extends State<AddNewAttraction>
{
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final ratingController = TextEditingController();

  File? file;

  @override
  void dispose()
  {
    titleController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    ratingController.dispose();
    super.dispose();
  }

  Future<void> uploadAttractionToDb() async
  {
    try
    {
      final id = const Uuid().v4();
      final imagesRef = FirebaseStorage.instance.ref('images').child(id);

      final uploadAttraction = imagesRef.putFile(file!);
      final attractionSnapshot = await uploadAttraction;
      final imageURL = await attractionSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("locations").doc(id).set({
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "creator": FirebaseAuth.instance.currentUser!.uid,
        "postedAt": FieldValue.serverTimestamp(),
        "imageURL": imageURL,
        "latitude": double.tryParse(latitudeController.text.trim()) ?? 0.0,
        "longitude": double.tryParse(longitudeController.text.trim()) ?? 0.0,
        "rating": double.tryParse(ratingController.text.trim()) ?? 0.0,
      });

      print("Attraction Uploaded with ID: $id");
    } catch (e)

    {
      print(e);
    }
  }

  Future<File?> selectImage() async
  {
    final picker = ImagePicker();

    return showModalBottomSheet<File?>(
      context: context,
      builder: (BuildContext context)
      {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async
                {
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, picked != null ? File(picked.path) : null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async
                {
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, picked != null ? File(picked.path) : null);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async
  {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled)
    {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
    {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever)
    {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(()
    {
      latitudeController.text = position.latitude.toString();
      longitudeController.text = position.longitude.toString();
    });
  }

  @override
  void initState()
  {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Attraction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: uploadAttractionToDb,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () async
                {
                  final image = await selectImage();
                  setState(()
                  {
                    file = image;
                  });
                },
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(10),
                  dashPattern: const [10, 4],
                  strokeCap: StrokeCap.round,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: file != null
                        ? Image.file(file!)
                        : const Center(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Rating (0 - 5)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: latitudeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: longitudeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}