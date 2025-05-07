import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'package:project/add_new_attraction.dart';
import 'package:flutter/cupertino.dart';
import 'package:project/view_attractions.dart';
import 'package:project/albums.dart';

final themeNotifier = ThemeNotifier();

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ValueListenableBuilder<ThemeMode>(
    valueListenable: themeNotifier,
    builder: (context, themeMode, _)
    {
      return MyApp(themeMode: themeMode);
    },
  ));
}

class MyApp extends StatelessWidget
{
  final ThemeMode themeMode;
  const MyApp({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      themeMode: themeMode,
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        fontFamily: 'Cera Pro',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.all(27),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot)
        {
          if (snapshot.connectionState == ConnectionState.waiting)
          {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.data != null)
          {
            return const HomeScreen();
          }
          return const SignUpPage();
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget
{
  const HomeScreen({super.key});

  Future<Position> _getCurrentLocation() async
  {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled)
    {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
    {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
      {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever)
    {
      throw Exception('Location permission permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<List<DocumentSnapshot>> _getNearestAttractions(Position userLocation) async
  {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('locations').get();

    List<DocumentSnapshot> attractions = snapshot.docs;

    attractions.sort((a, b)
    {
      GeoPoint locA = a['location'];
      GeoPoint locB = b['location'];

      double distanceA = Geolocator.distanceBetween(
          userLocation.latitude, userLocation.longitude, locA.latitude, locA.longitude);
      double distanceB = Geolocator.distanceBetween(
          userLocation.latitude, userLocation.longitude, locB.latitude, locB.longitude);

      return distanceA.compareTo(distanceB);
    });

    return attractions.take(3).toList();
  }

  void _showNearbyAttractions(BuildContext context) async
  {
    try
    {
      Position userLocation = await _getCurrentLocation();
      List<DocumentSnapshot> nearestAttractions = await _getNearestAttractions(userLocation);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nearby Attractions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: nearestAttractions.map((doc)
            {
              return ListTile(
                title: Text(doc['title']),
                subtitle: Text(doc['description']),
              );
            }).toList(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: Text('Photo Journal')), 
      drawer: AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: ()
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewAttraction(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Add Attraction'),
            ),

            ElevatedButton.icon(
              onPressed: ()
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewAttractionsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('View All Attractions'),
            ),

            ElevatedButton.icon(
              onPressed: ()
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddToAlbumPage(),
                  ),
                );
              },
              icon: const Icon(Icons.photo_album_outlined),
              label: const Text('Add to Album'),
            ),

            const SizedBox(height: 16),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("locations")
                  .where('creator', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot)
              {
                if (snapshot.connectionState == ConnectionState.waiting)
                {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData)
                {
                  return const Text('No data here :(');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index)
                  {
                    return Row(
                      children: [
                        Expanded(
                          child: AttractionCard(
                            headerText: snapshot.data!.docs[index]['title'],
                            descriptionText: snapshot.data!.docs[index]['description'],
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: strengthenColor(const Color.fromRGBO(246, 222, 194, 1), 0.69),
                            image: snapshot.data!.docs[index]['imageURL'] == null
                                ? null
                                : DecorationImage(
                                    image: NetworkImage(snapshot.data!.docs[index]['imageURL']),
                                  ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.all(12.0)),
                      ],
                    );
                  },
                );
              },
            ),
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
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: ()
            {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: ()
            {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget
{
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
{
  bool isDarkMode = themeNotifier.value == ThemeMode.dark;

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SwitchListTile(
        title: const Text('Dark Mode'),
        value: isDarkMode,
        onChanged: (value)
        {
          setState(() => isDarkMode = value);
          themeNotifier.toggleTheme(value);
        },
      ),
    );
  }
}

class AttractionCard extends StatelessWidget
{
  final String headerText;
  final String descriptionText;

  const AttractionCard({
    super.key,
    required this.headerText,
    required this.descriptionText,
  });

  @override
  Widget build(BuildContext context)
  {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        title: Text(headerText),
        subtitle: Text(descriptionText),
      ),
    );
  }
}

class ThemeNotifier extends ValueNotifier<ThemeMode>
{
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme(bool isDark)
  {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

Color strengthenColor(Color color, double amount)
{
  assert(amount >= 0 && amount <= 1);
  return Color.fromRGBO(
    (color.r * amount).clamp(0, 255).toInt(),
    (color.g * amount).clamp(0, 255).toInt(),
    (color.b * amount).clamp(0, 255).toInt(),
    1,
  );
}

class AboutPage extends StatelessWidget
{
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            Text(
              'Photo Journal App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'This app allows users to record and explore attractions and personal travel memories. '
              'You can create attractions with photos, geotag them with your GPS, view them on a map, '
              'add them to albums, and share feedback with comments and ratings.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              'Technology',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Flutter app'),
            Text('• Widgets:'),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('◦ GPS'),
                  Text('◦ Geocoding'),
                  Text('◦ Firebase connector'),
                  Text('◦ Camera'),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text('• Database: Firebase'),
          ],
        ),
      ),
    );
  }
}