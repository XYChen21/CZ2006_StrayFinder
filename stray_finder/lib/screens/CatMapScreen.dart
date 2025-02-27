import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../ui/MapUI.dart';
import '../widgets/CatInfoWidget.dart';
import '../widgets/MapLegendWidget.dart';
import 'dart:async';

/// A screen to show all cats on Google Maps
class CatMapScreen extends StatefulWidget {
  const CatMapScreen({ Key? key }) : super(key: key);

  @override
  State<CatMapScreen> createState() => _CatMapScreenState();
}

/// State of the page
class _CatMapScreenState extends State<CatMapScreen> {
  ///A controller to control the info window that shows the description of the cat when a marker is pressed
  final CustomInfoWindowController _controller = CustomInfoWindowController();
  ///An attribute to indicate an uninjured cat's marker on a map
  late Future<Uint8List> _normalCatMarker;
///An attribute to indicate an injured cat's marker on a map
  late Future<Uint8List> _injuredCatMarker;

  @override
  void initState() {
    super.initState();
    _normalCatMarker = MapUI.getMarkerFromAsset('assets/images/cat_marker0.png');
    _injuredCatMarker = MapUI.getMarkerFromAsset('assets/images/cat_marker1.png');
  }
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

///A method to create markers for the cats on a map
  Set<Marker> _createMarkers(List<dynamic> cats, List<Uint8List> catMarker){
    Set<Marker> marker = {};
    marker.addAll(cats.map((cat) {
      LatLng pos = LatLng(cat['lastSeenLoc'].latitude, cat['lastSeenLoc'].longitude);
      return Marker(
        markerId: MarkerId(cat['cat_id'].toString()),
        position: pos,
        icon: cat['is_injured']? BitmapDescriptor.fromBytes(catMarker[1]): BitmapDescriptor.fromBytes(catMarker[0]),
        onTap: (){
          _controller.addInfoWindow!(
            CatInfoWidget(cat, _controller),
            pos,
          );
        }
      );
    }));
    return marker;
  }
  @override

  ///A method to build the page
  Widget build(BuildContext context) {
    late List<Uint8List> catMarker;
    late List<Map<String, dynamic>> cats;
    return FutureBuilder(
      future: Future.wait([_normalCatMarker, _injuredCatMarker]),
      builder: (BuildContext context, AsyncSnapshot<List<Uint8List>> snapshotF){
        if (snapshotF.hasData){
          catMarker = snapshotF.data!;
          return Scaffold(
            body: Stack(
              alignment: AlignmentDirectional.topEnd,
              children: [
                StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('cats').snapshots(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshotB){
                    if (snapshotB.hasData){
                      var c = snapshotB.data!.docs as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
                      cats = c.map((value) => value.data()).toList();                    
                      return GoogleMap(
                        myLocationButtonEnabled: false,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(1.3521, 103.8198),
                          zoom: 11.5,
                        ),
                        markers: _createMarkers(cats, catMarker),
                        onCameraMove: (position) {
                          _controller.onCameraMove!();
                        },
                        onMapCreated: (GoogleMapController controller) async {
                          _controller.googleMapController = controller;
                        },
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  }
                ),
                CustomInfoWindow(
                  controller: _controller,
                  height: 170,
                  width: 180,
                  offset: 45,
                ),
                const Align(
                  alignment: Alignment(0.95,-0.97),
                  child: MapLegendWidget(),
                ),
              ],
            ),
          );
        } else{
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(),)
          );
        }
      }
    );
  }
}