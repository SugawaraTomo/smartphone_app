import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late GoogleMapController mapController;

  //   現在地を監視するためのstream
  late StreamSubscription<Position> positionStream;
  Set<Marker> markers = {};

  final CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 16.0,
  );

  // 現在地通知の設定
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, //正確性:highはAndroid(0-100m),iOS(10m)
    distanceFilter: 0,
  );

  @override
  void dispose() {
    mapController.dispose();
    // Streamを閉じる
    positionStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: <Widget>[
      GoogleMap(
        initialCameraPosition: initialCameraPosition,
        onMapCreated: (GoogleMapController controller) async {
          mapController = controller;
          await _requestPermission();
          await _moveToCurrentLocation();
          _watchCurrentLocation();
        },
        onLongPress: (LatLng latLang) {
          setState(() {
            markers.add(Marker(
              markerId: const MarkerId('tapped_location'),
              position: LatLng(
                latLang.latitude,
                latLang.longitude,
              ),
            ));
          });
        },
        myLocationButtonEnabled: false,
        markers: markers,
      ),
          Center(
            child: OutlinedButton(
              onPressed: (){},//_showNotification,
              child: Text('通知を表示'),
            ),
          ),
    ]));
  }

  @override
  void initState() {
    super.initState();

    _initializePlatformsSpecifics();
  }

  void _initializePlatformsSpecifics() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveBackgroundNotificationResponse: (NotificationResponse res) {
      debugPrint('payload:${res.payload}');
    });
  }

  void _watchCurrentLocation() {
    // 現在地を監視
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) async {
      // マーカーの位置を更新
      setState(() {
        markers.removeWhere(
            (marker) => marker.markerId == const MarkerId('current_location'));

        markers.add(Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            position.latitude,
            position.longitude,
          ),
        ));
      });
      // 現在地にカメラを移動
      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    });
  }

  Future<void> _showNotification() async {
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID',
      'CHANNEL_NAME',
      channelDescription: "CHANNEL_DESCRIPTION",
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      timeoutAfter: 5000,
      styleInformation: DefaultStyleInformation(true, true),
    );

    var platformChannelSpecifics =
        NotificationDetails(android: androidChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'お知らせ', // Notification Title
      '～について', // Notification Body, set as null to remove the body
      platformChannelSpecifics,
      payload: 'New Payload', // Notification Payload
    );
  }

  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _moveToCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // 現在地を取得
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        markers.add(Marker(
          markerId: const MarkerId("current_location"),
          position: LatLng(
            position.latitude,
            position.longitude,
          ),
        ));
      });

      // 現在地にカメラを移動
      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    }
  }
}
