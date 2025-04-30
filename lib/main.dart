import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project/home_page.dart';
import 'package:project/signup_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';


void main() async
{
  WidgetFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
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
              // color: Pallete.gradient2,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.data != null) {
            return const MyHomePage();
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
            ElevatedButton(
              child: Text('Add Attraction'),
              actions: [
                IconButton(
                  onPressed: ()
                  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddNewAttraction(),
                      ),
                    );
                  },
                  icon: const Icon(
                    CupertinoIcons.add,
                  ),
                ),
              ],
              body: Center(
                child: Column(
                  children: [
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("locations")
                          .where('creator', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                          .snapshots(),
                      builder: (context, snapshot)
                      {
                        if (snapshot.connectionState == ConnectionState.waiting)
                        {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData)
                        {
                          return const Text('No data here :(');
                        }

                        return Expanded(
                          child: ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index)
                            {
                              return Row(
                                children: [
                                  Expanded(
                                    child: AttractionCard(
                                      headerText:
                                          snapshot.data!.docs[index].data()['title'],
                                      descriptionText: snapshot.data!.docs[index]
                                          .data()['description'],
                                    ),
                                  ),
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: strengthenColor(
                                        const Color.fromRGBO(246, 222, 194, 1),
                                        0.69,
                                      ),
                                      image: snapshot.data!.docs[index]
                                                  .data()['imageURL'] ==
                                              null
                                          ? null
                                          : DecorationImage(
                                              image: NetworkImage(
                                                snapshot.data!.docs[index]
                                                    .data()['imageURL'],
                                              ),
                                            ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                  )
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('View Attractions'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('Nearby Attractions'),
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
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}