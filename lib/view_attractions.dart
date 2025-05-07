import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

class ViewAttractionsPage extends StatefulWidget {
  const ViewAttractionsPage({super.key});

  @override
  State<ViewAttractionsPage> createState() => _ViewAttractionsPageState();
}

class _ViewAttractionsPageState extends State<ViewAttractionsPage>
{
  double userLat = 0.0;
  double userLon = 0.0;
  double rangeKm = 10.0;

  @override
  void initState()
  {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async
  {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(()
    {
      userLat = position.latitude;
      userLon = position.longitude;
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Attractions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text("Range (km): "),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "e.g. 10"),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null)
                      {
                        setState(() => rangeKm = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('locations').snapshots(),
              builder: (context, snapshot)
              {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.where((doc)
                {
                  final data = doc.data() as Map<String, dynamic>;
                  final lat = data['latitude'] ?? 0.0;
                  final lon = data['longitude'] ?? 0.0;
                  final distance = calculateDistance(userLat, userLon, lat, lon);
                  return distance <= rangeKm;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No nearby attractions.'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index)
                  {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    data['id'] = id;
                    return ListTile(
                      title: Text(data['title'] ?? 'No Title'),
                      subtitle: Text(data['description'] ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttractionDetailsPage(data: data),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AttractionDetailsPage extends StatelessWidget
{
  final Map<String, dynamic> data;

  const AttractionDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context)
  {
    final docId = data['id'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? 'Attraction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: ()
            {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditAttractionPage(data: data, docId: docId),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['imageURL'] != null)
              Image.network(data['imageURL'], height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text('Title: ${data['title'] ?? 'N/A'}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('Description: ${data['description'] ?? 'N/A'}'),
            Text('Rating: ${data['rating']?.toStringAsFixed(1) ?? 'N/A'}'),
            const Divider(height: 30),

            CommentSection(attractionId: docId),
          ],
        ),
      ),
    );
  }
}

class EditAttractionPage extends StatefulWidget
{
  final Map<String, dynamic> data;
  final String docId;

  const EditAttractionPage({super.key, required this.data, required this.docId});

  @override
  State<EditAttractionPage> createState() => _EditAttractionPageState();
}

class _EditAttractionPageState extends State<EditAttractionPage>
{
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController ratingController;

  @override
  void initState()
  {
    super.initState();
    titleController = TextEditingController(text: widget.data['title']);
    descriptionController = TextEditingController(text: widget.data['description']);
    ratingController = TextEditingController(text: widget.data['rating']?.toString());
  }

  @override
  void dispose()
  {
    titleController.dispose();
    descriptionController.dispose();
    ratingController.dispose();
    super.dispose();
  }

  void _saveChanges() async
  {
    await FirebaseFirestore.instance.collection('locations').doc(widget.docId).update({
      'title': titleController.text,
      'description': descriptionController.text,
      'rating': double.tryParse(ratingController.text) ?? 0.0,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Attraction')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: ratingController,
              decoration: const InputDecoration(labelText: 'Rating'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveChanges, child: const Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}

class CommentSection extends StatefulWidget
{
  final String attractionId;

  const CommentSection({super.key, required this.attractionId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection>
{
  final commentController = TextEditingController();
  double rating = 3.0;

  void _submitComment() async
  {
    await FirebaseFirestore.instance.collection('locations').doc(widget.attractionId).collection('comments').add({
      'comment': commentController.text.trim(),
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });

    commentController.clear();
    setState(() => rating = 3.0);
  }

  @override
  Widget build(BuildContext context)
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('locations')
              .doc(widget.attractionId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot)
          {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final comments = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index)
              {
                final c = comments[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(c['comment'] ?? ''),
                  subtitle: Text('Rating: ${c['rating'] ?? ''}'),
                );
              },
            );
          },
        ),
        const Divider(),
        TextField(
          controller: commentController,
          decoration: const InputDecoration(labelText: 'Add a comment'),
        ),
        Row(
          children: [
            const Text('Rating:'),
            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: rating.toString(),
              onChanged: (val) => setState(() => rating = val),
            ),
            ElevatedButton(onPressed: _submitComment, child: const Text('Post')),
          ],
        ),

        const SizedBox(height: 20),
        const Text('All Reviews', style: TextStyle(fontSize: 18)),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('locations')
              .doc(widget.attractionId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot)
          {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final comments = snapshot.data!.docs;
            if (comments.isEmpty) return const Text('No reviews yet.');

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index)
              {
                final comment = comments[index].data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(comment['comment'] ?? ''),
                  subtitle: Text('Rating: ${comment['rating']?.toStringAsFixed(1) ?? ''}'),
                  trailing: Text(
                    (comment['createdAt'] as Timestamp?)?.toDate().toLocal().toString().split('.').first ?? '',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2)
{
  const p = 0.017453292519943295;
  final a = 0.5 - cos((lat2 - lat1) * p)/2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}