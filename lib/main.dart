import 'package:flutter/material.dart';
import 'dart:io';

void main()
{
  runApp(MyApp());
}

class MyApp extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      title: 'Attraction Memories',
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      drawer: AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 250,
              ),
              Container(
                height: 250,
                color: Colors.blue,
                alignment: Alignment.center,
                child: Text(
                  'Welcome to Attraction Memories!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore and capture your favorite attractions.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  children: [
                    _buildFeatureCard(context, Icons.camera, 'Add Attraction', AddAttractionScreen()),
                    _buildFeatureCard(context, Icons.place, 'Nearby Attractions', NearbyAttractionsScreen()),
                    _buildFeatureCard(context, Icons.info, 'About', AboutScreen()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String title, Widget screen) {
    return Card(
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            title: Text('Home'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen())),
          ),
          ListTile(
            title: Text('Add Attraction'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddAttractionScreen())),
          ),
          ListTile(
            title: Text('Nearby Attractions'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NearbyAttractionsScreen())),
          ),
          ListTile(
            title: Text('About'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen())),
          ),
        ],
      ),
    );
  }
}

class AddAttractionScreen extends StatefulWidget
{
  @override
  _AddAttractionScreenState createState() => _AddAttractionScreenState();
}

class _AddAttractionScreenState extends State<AddAttractionScreen>
{
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  File? _image;

  void _createPost()
  {
    String description = _descriptionController.text;
    String tags = _tagsController.text;
    if (_image != null && description.isNotEmpty)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post Created!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a photo and description.')),
      );
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: Text('Add Attraction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!, height: 200),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: null,
              child: Text('Take a Photo'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(labelText: 'Tags (comma separated)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createPost,
              child: Text('Create Post'),
            ),
          ],
        ),
      ),
    );
  }
}

class NearbyAttractionsScreen extends StatefulWidget
{
  @override
  _NearbyAttractionsScreenState createState() => _NearbyAttractionsScreenState();
}

class _NearbyAttractionsScreenState extends State<NearbyAttractionsScreen>
{
  final List<Map<String, String>> _attractions = [
    {'name': 'Central Park', 'location': 'New York, USA', 'description': 'A large city park with lakes, trails, and gardens.'},
    {'name': 'Eiffel Tower', 'location': 'Paris, France', 'description': 'An iconic tower in the heart of Paris.'},
    {'name': 'Great Wall of China', 'location': 'China', 'description': 'A historical wall stretching thousands of miles.'},
  ];

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: Text('Nearby Attractions')),
      body: ListView.builder(
        itemCount: _attractions.length,
        itemBuilder: (context, index)
        {
          final attraction = _attractions[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(attraction['name']!),
              subtitle: Text(attraction['location']!),
              onTap: ()
              {
                showDialog(
                  context: context,
                  builder: (context)
                  {
                    return AlertDialog(
                      title: Text(attraction['name']!),
                      content: Text(attraction['description']!),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AboutScreen extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Attraction Memories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Attraction Memories is a Flutter-based application that allows users to explore, record, and share their experiences at various attractions.  Users can take photos, add descriptions, and tag their memories.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Technologies Used:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('- Flutter app', style: TextStyle(fontSize: 16)),
            Text('- Widgets:', style: TextStyle(fontSize: 16)),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• GPS', style: TextStyle(fontSize: 16)),
                  Text('• Geocoding', style: TextStyle(fontSize: 16)),
                  Text('• Firebase connector', style: TextStyle(fontSize: 16)),
                  Text('• Camera', style: TextStyle(fontSize: 16)),
                  Text('• Google Maps', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text('- Database: Firebase', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}