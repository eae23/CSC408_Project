import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:frontend/utils.dart';
import 'package:uuid/uuid.dart';

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
      final imagesRef =
          FirebaseStorage.instance.ref('images').child(id);

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
                controller: latitudeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Latitude',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: longitudeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Longitude',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Rating (0 - 5)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}