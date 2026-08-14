import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Import the Timer class
import 'package:intl/intl.dart'; // Import for date formatting

class MapScreen extends StatefulWidget {
  MapScreen();

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> _locations = [];
  List<String> facultyNames = [];
  Timer? _timer;
  DateTime? _lastSyncTime; // Track the last sync time

  @override
  void initState() {
    super.initState();
    _fetchLocations(); // Fetch locations once on startup
    _startLocationUpdate(); // Start periodic location updates
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Start the timer to fetch location every 1 minute
  void _startLocationUpdate() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchLocations();
      print(_locations);
    });
  }

  Future<void> _fetchLocations() async {
    final response = await Supabase.instance.client
        .from('faculty')
        .select('location'); // Adjust this field as needed
    final response2 = await Supabase.instance.client
        .from('faculty')
        .select('name'); // Adjust this field as needed

    final locations = response as List<dynamic>;
    print(locations);
    final names = response2 as List<dynamic>;
    List<LatLng> latLngList = [];
    List<String> nameList = [];
    for (var location in locations) {
      String locString = location['location']; // Adjust the field name as needed

      List<String> latLngParts = locString.split(',');

      if (latLngParts.length == 2) {
        double latitude = double.parse(latLngParts[0]);
        double longitude = double.parse(latLngParts[1]);
        latLngList.add(LatLng(latitude, longitude));
      }
    }
    for (var entry in names) {
      String name = entry['name'];
      print(name);
      nameList.add(name);
    }

    setState(() {
      _locations = latLngList;
      facultyNames = nameList;
      _lastSyncTime = DateTime.now(); // Update sync time
    });
  }

  List<Marker> _createMarkers() {
    List<Marker> markers = [];
    markers.add(Marker(
      point: LatLng(19.9524, 73.8632),
      width: 200,
      height: 50,
      child: Center(
        child: Text(
          'Government Poly Nashik',
          style: TextStyle(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ),
    ));

    // Ensure facultyNames and _locations are of the same length
    for (int i = 0; i < facultyNames.length && i < _locations.length; i++) {
      markers.add(
        Marker(
          point: _locations[i],
          width: 80,
          height: 80,
          child: Container(
            child: Column(
              children: [
                Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 30,
                ),
                Text(
                  facultyNames[i],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    String formattedSyncTime = _lastSyncTime != null
        ? DateFormat('yyyy-MM-dd – kk:mm').format(_lastSyncTime!)
        : 'Never';

    return Scaffold(
      appBar: AppBar(title: Text("Track Faculty's Location")),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(19.9524, 73.8632),
                initialZoom: 15.5,
                minZoom: 10,
                maxZoom: 17,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _createMarkers(),
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(19.9524, 73.8632),
                      useRadiusInMeter: true,
                      radius: 300, // Set the radius in meters
                      color: Color(0xFF006491).withOpacity(0.2), // Transparent grey color
                      borderStrokeWidth: 1,
                      borderColor: Color(0xFF006491),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last Synced: $formattedSyncTime',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
