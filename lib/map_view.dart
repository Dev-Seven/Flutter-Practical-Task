import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng mapCenter = const LatLng(23.022505, 72.571365);
  late ConnectivityResult _connectivityResult;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadMarkers();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectivityResult = result;
      });
    });
  }

  Future<void> _initConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = result;
      const SnackBar(content: Text('Check your internet'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map App'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: mapCenter,
          zoom: 12.0,
        ),
        markers: markers,
        onCameraMove: _onCameraMove,
        onTap: _onMapTap,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _addMarker();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(seconds: 2),
                content: Text('Add'),
              ));
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              _removeMarkers();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(seconds: 2),
                content: Text('Clear'),
              ));
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              _saveMarkers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(duration: Duration(seconds: 2),
                  content: Text('Saved'),
                ),
              );
            },
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      mapCenter = position.target;
    });
    print(
        'Map center: ${position.target.latitude}, ${position.target.longitude}');
  }

  bool isMarkerAdded(LatLng position) {
    return markers.any((marker) => marker.position == position);
  }

  void _onMapTap(LatLng latLng) {
    if (isMarkerAdded(latLng)) {
      _removeMarkerAtPosition(latLng);
    } else {
      _addMarkerAtPosition(latLng);
    }
  }

  void _addMarker() {
    final String label = 'Marker ${markers.length + 1}';

    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(label),
          position: mapCenter,
          infoWindow: InfoWindow(
            title: label,
            snippet: '',
          ),
        ),
      );
    });
  }

  void _addMarkerAtPosition(LatLng position) {
    final String label = 'Marker ${markers.length + 1}';

    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(label),
          position: position,
          infoWindow: InfoWindow(
            title: label,
            snippet: '$position',
          ),
        ),
      );
    });
  }

  void _removeMarkerAtPosition(LatLng position) {
    setState(() {
      markers.removeWhere((marker) => marker.position == position);
    });
  }

  void _removeMarkers() {
    setState(() {
      markers.clear();
      clearData();
    });
  }

  void clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.clear();
    });
  }

  Future<void> _saveMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> markersList = markers
        .map((marker) =>
            "${marker.position.latitude},${marker.position.longitude},${marker.infoWindow.title}")
        .toList();

    prefs.setStringList('markers', markersList);
  }

  Future<void> _loadMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? markersList = prefs.getStringList('markers');

    if (markersList != null) {
      setState(() {
        markers = markersList.map((markerString) {
          List<String> parts = markerString.split(',');
          return Marker(
            markerId: MarkerId(parts[2]),
            position: LatLng(double.parse(parts[0]), double.parse(parts[1])),
            infoWindow: InfoWindow(
              title: parts[2],
              snippet: '',
            ),
          );
        }).toSet();
      });
    }
  }
}
