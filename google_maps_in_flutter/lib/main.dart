import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'locations.dart' as locations;

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, Marker> _markers = {};


  Future<void> _onMapCreated(GoogleMapController controller) async {
    final googleoffices = await locations.getGoogleOffices();
    setState(() {
      _markers.clear();

      for (final office in googleoffices.offices) {
        final marker = Marker(
            markerId: MarkerId(office.name),
            position: LatLng(office.lat, office.lng),
            infoWindow:
                InfoWindow(title: office.name, snippet: office.address));
        _markers[office.name] = marker;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Maps Sample App'),
          ),
          body: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: LatLng(0,0), zoom: 2),
            markers: _markers.values.toSet(),
          )),
    );
  }
}
