import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddToAlbumPage extends StatefulWidget
{
  const AddToAlbumPage({super.key});

  @override
  State<AddToAlbumPage> createState() => _AddToAlbumPageState();
}

class _AddToAlbumPageState extends State<AddToAlbumPage>
{
  final TextEditingController _albumNameController = TextEditingController();
  final Set<String> _selectedLocationIds = {};

  Future<void> _createAlbum() async
  {
    final albumName = _albumNameController.text.trim();
    if (albumName.isEmpty || _selectedLocationIds.isEmpty)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album name and at least one location are required')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('albums').add({
      'name': albumName,
      'creator': userId,
      'locationIds': _selectedLocationIds.toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Album created successfully!')),
    );

    _albumNameController.clear();
    _selectedLocationIds.clear();
    setState(() {}); // Refresh selection state
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Album")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _albumNameController,
              decoration: const InputDecoration(labelText: 'Album Name'),
            ),
            const SizedBox(height: 16),
            const Text("Select Attractions to Add"),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('locations')
                    .where('creator', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot)
                {
                  if (snapshot.connectionState == ConnectionState.waiting)
                  {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  {
                    return const Center(child: Text('No attractions found.'));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index)
                    {
                      final doc = docs[index];
                      final docId = doc.id;
                      final isSelected = _selectedLocationIds.contains(docId);

                      return GestureDetector(
                        onTap: ()
                        {
                          setState(()
                          {
                            if (isSelected)
                            {
                              _selectedLocationIds.remove(docId);
                            }
                            else
                            {
                              _selectedLocationIds.add(docId);
                            }
                          });
                        },
                        child: Card(
                          color: isSelected ? Colors.blue.shade100 : null,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: doc['imageURL'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      doc['imageURL'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.image_not_supported, size: 40),
                            title: Text(doc['title']),
                            subtitle: Text(doc['description']),
                            trailing: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _createAlbum,
              icon: const Icon(Icons.create_new_folder),
              label: const Text("Create Album"),
            )
          ],
        ),
      ),
    );
  }
}