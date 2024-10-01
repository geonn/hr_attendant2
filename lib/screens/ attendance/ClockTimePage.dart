import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hr_attendant/provider/attendance_provider.dart';
import 'package:hr_attendant/services/attendant_service.dart';
import 'package:hr_attendant/widgets/home/buildCircleButton.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ClockTimePage extends StatefulWidget {
  final VoidCallback onClockTimeSuccess;
  //final File selfie;
  const ClockTimePage({
    super.key,
    required this.onClockTimeSuccess,
  }); // required this.selfie});
  @override
  _ClockTimePageState createState() => _ClockTimePageState();
}

class _ClockTimePageState extends State<ClockTimePage> {
  var log = Logger();
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  String _placeName = '';
  File? _selfieImage;
  String _time = '';
  bool isLoading = false;
  var otTimeStr;

  @override
  void initState() {
    super.initState();
    _showLocation();
  }

  String getCurrentDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(now);
  }

  void _currentTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = DateFormat('hh:mm:ss a').format(now);
    setState(() {
      _time = formattedDateTime;
    });
  }

  Future<File> resizeImage(File imageFile, {int targetWidth = 640}) async {
    // Read the image from the file
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) {
      throw Exception('Failed to decode image.');
    }

    // Calculate the new height to maintain the aspect ratio
    final int targetHeight = (image.height * targetWidth / image.width).round();

    // Resize the image
    img.Image resizedImage =
        img.copyResize(image, width: targetWidth, height: targetHeight);

    // Generate a new file path with '-resized' appended to the file name
    final filePath = imageFile.absolute.path;
    final lastIndex = filePath.lastIndexOf('.');
    final newPath =
        '${filePath.substring(0, lastIndex)}-resized${filePath.substring(lastIndex)}';

    // Save the resized image to the new file
    final resizedFile = File(newPath);
    await resizedFile.writeAsBytes(img.encodeJpg(resizedImage));

    return resizedFile;
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 600,
        maxWidth: 600,
        requestFullMetadata: true,

        imageQuality:
            100, // Optionally reduce the image quality when capturing the image
      );
      File correctFile = correctImageOrientation(File(pickedFile!.path));
      bool hasFace = await detectFace(correctFile);
      if (hasFace) {
        setState(() {
          _selfieImage = correctFile;
        });
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No Face Detected'),
              content: const Text(
                  'Please capture a photo with a clear view of your face.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      log.d("error: $error");
    }
  }

  File correctImageOrientation(File imageFile) {
    final originalImage = img.decodeImage(imageFile.readAsBytesSync());

    // Check the orientation (just an example, you'd need to fetch the actual orientation from EXIF)
    const orientation = 1;

    img.Image orientedImage;
    print(orientation);
    switch (orientation) {
      case 1:
        orientedImage = originalImage!;
        break;
      case 3:
        orientedImage = img.copyRotate(originalImage!, angle: 180);
        break;
      case 6:
        orientedImage = img.copyRotate(originalImage!, angle: 90);
        break;
      case 8:
        orientedImage = img.copyRotate(originalImage!, angle: -90);
        break;
      default:
        orientedImage = originalImage!;
    }

    final correctedImageFile = File(imageFile.path)
      ..writeAsBytesSync(img.encodeJpg(orientedImage));

    return correctedImageFile;
  }

  Future<bool> detectFace(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final options = FaceDetectorOptions(
        enableTracking: true,
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate);
    final faceDetector = FaceDetector(options: options);
    final List<Face> faces = await faceDetector.processImage(inputImage);
    print("detectFace");
    print(faces);
    await faceDetector.close();

    // If faces are detected, return true, else false.
    return faces.isNotEmpty;
  }

  void _showLocation() async {
    Position position = await getCurrentLocation();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _placeName = await _getPlaceName(position.latitude, position.longitude);
    setState(() {});
  }

  Future<String> _getPlaceName(double latitude, double longitude) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);
    log.d(placemarks);

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks.first;

      List<String> addressComponents = [
        placemark.name ?? '',
        placemark.subThoroughfare ?? '',
        placemark.thoroughfare ?? '',
        placemark.subLocality ?? '',
        placemark.locality ?? '',
        placemark.subAdministrativeArea ?? '',
        placemark.administrativeArea ?? '',
        placemark.postalCode ?? '',
        placemark.country ?? ''
      ];

      // Remove redundant address components
      for (int i = 0; i < addressComponents.length; i++) {
        for (int j = 0; j < addressComponents.length; j++) {
          if (i != j &&
              addressComponents[i].contains(addressComponents[j]) &&
              addressComponents[j].isNotEmpty) {
            addressComponents[j] = '';
          }
        }
      }

      // Filter out empty components and concatenate the refined address components
      String address = addressComponents
          .where((component) => component.isNotEmpty)
          .join(', ')
          .trim();

      return address;
    }

    return 'No place name found';
  }

  Future<Position> getCurrentLocation() async {
    // Request location permission if not already granted
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return position;
  }

  /* for research google map only. can remove anytime. */
  Future<Uint8List> getImages(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return Uint8List.fromList(response.bodyBytes);
    } else {
      throw Exception('Failed to load image');
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    //final Uint8List markIcons = await getImages("");
    //BitmapDescriptor.fromBytes(markIcons);
  }

  Future<String?> showMiscellaneousOptionsDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select an Option'),
          children: <Widget>[
            SimpleDialogOption(
              child: const Text('Client Appointment'),
              onPressed: () => Navigator.of(context).pop('Client Appointment'),
            ),
            SimpleDialogOption(
              child: const Text('Night Shift'),
              onPressed: () => Navigator.of(context).pop('Night Shift'),
            ),
            SimpleDialogOption(
              child: const Text('Standby'),
              onPressed: () => Navigator.of(context).pop('Standby'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitData(String action) async {
    setState(() {
      isLoading = true;
    });
    // Prepare the data for submission
    if (_selfieImage == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Upload Selfie'),
            content: const Text('Please upload a selfie photo to proceed.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the AlertDialog
                },
              ),
            ],
          );
        },
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmation'),
              content:
                  Text('Are you sure you want to Clock $action at this time?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Return false
                  },
                ),
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // Return true
                  },
                ),
              ],
            );
          },
        ) ??
        false; // If the user closes the dialog without pressing 'Yes' or 'No', we assume 'No'

    if (!confirm) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    String placeName = _placeName;
    String coordinates =
        '${_currentLocation!.latitude}, ${_currentLocation!.longitude}';

    // Submit the data to the API
    try {
      AttendantService attendantService = AttendantService();
      // TODO: Make sure to include the necessary headers and data structure for the API request
      Map<String, dynamic>? response = await attendantService.doClockInOut(
          getCurrentDate(),
          _time,
          _placeName,
          _currentLocation!.longitude,
          _currentLocation!.latitude,
          _selfieImage!,
          action);
      if (response != null && response.containsKey('data2')) {
        otTimeStr = response['data2'];
        DateTime now = DateTime.now();
        DateTime otTime = DateFormat("HH:mm:ss").parse(otTimeStr);

        // Create DateTime objects using today's date but the time from now and otTime
        DateTime nowTime = DateTime(
            now.year, now.month, now.day, now.hour, now.minute, now.second);
        DateTime otDateTime = DateTime(now.year, now.month, now.day,
            otTime.hour, otTime.minute, otTime.second);

        // Compare if now is after the overtime start time
        if (nowTime.isAfter(otDateTime) && false) {
          // Show dialog to confirm overtime
          bool checkApplyOvertime = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Overtime'),
                    content: const Text(
                        'Do you want to apply this period as overtime?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text('Yes'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              ) ??
              false; // Use 'false' as a default value in case nothing is returned

          // If user confirmed, apply for overtime
          if (checkApplyOvertime) {
            print('_showApplyOvertimeForm');
            _showApplyOvertimeForm();
          } else {
            String message = response['message'];
            BuildContext currentContext = context;
            print('onClockTimeSuccess');
            widget.onClockTimeSuccess();
            print('success?');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: currentContext,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Success'),
                    content: Text(message),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the AlertDialog
                          Navigator.of(currentContext)
                              .pop(); // Close the current page
                        },
                      ),
                    ],
                  );
                },
              );
            });
          }
        } else if (response['status'] == 'success') {
          if (action == "out") {
            // Cancel the scheduled notification
            SharedPreferences prefs = await SharedPreferences.getInstance();

            int? scheduledNotificationId =
                prefs.getInt('scheduledNotificationId');
            prefs.remove('scheduledNotificationId');
            if (scheduledNotificationId != null) {
              FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
                  FlutterLocalNotificationsPlugin();
              print("flutterLocalNotificationsPlugin.cancel");
              await flutterLocalNotificationsPlugin
                  .cancel(scheduledNotificationId);
            }
          } else {
            scheduleNotification(response['data3']);
          }

          String message = response['message'];
          BuildContext currentContext = context;
          widget.onClockTimeSuccess();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: currentContext,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Success'),
                  content: Text(message),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the AlertDialog
                        Navigator.of(currentContext)
                            .pop(); // Close the current page
                      },
                    ),
                  ],
                );
              },
            );
          });
        }
      }
    } catch (error) {
      // Handle submission error
      print('Error submitting data: $error');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clock Time'),
      ),
      body: Stack(
        children: [
          if (_currentLocation != null)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Colors.white,
              ),
              height: MediaQuery.of(context).size.height * 0.45,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              if (_selfieImage == null)
                                CircleButton(
                                    onPressed: _pickImage,
                                    text: "Take Selfie",
                                    buttonSize: ButtonSize.small),
                              if (_selfieImage != null)
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white, width: 5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 6,
                                        offset: const Offset(
                                            0, 3), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(_selfieImage!,
                                        filterQuality: FilterQuality.low,
                                        scale: 1.0,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(getCurrentDate()),
                              const SizedBox(
                                height: 10,
                              ),
                              const Text(
                                'Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              StreamBuilder(
                                stream: Stream.periodic(
                                    const Duration(seconds: 1),
                                    (_) => _currentTime()),
                                builder: (context, snapshot) {
                                  return Text(_time);
                                },
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              const Text(
                                'Place',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(_placeName),
                            ],
                          )),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      isLoading
                          ? const LinearProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _submitData("in");
                                      },
                                      style: ElevatedButton.styleFrom(
                                          side: BorderSide(
                                            width: 5.0,
                                            color: Theme.of(context)
                                                .primaryColorLight,
                                          ),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(40),
                                              bottomLeft: Radius.circular(40),
                                            ),
                                          ),
                                          backgroundColor: Theme.of(context)
                                              .secondaryHeaderColor),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 30.0),
                                        child: FittedBox(
                                          fit: BoxFit.fitWidth,
                                          child: Text(
                                            'Clock In',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final result =
                                            await showMiscellaneousOptionsDialog(
                                                context);
                                        if (result != null) {
                                          _submitData(result);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(0),
                                              bottomRight: Radius.circular(0),
                                            ),
                                          ),
                                          side: BorderSide(
                                            width: 5.0,
                                            color: Theme.of(context)
                                                .primaryColorLight,
                                          ),
                                          backgroundColor: Theme.of(context)
                                              .secondaryHeaderColor),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 30.0),
                                        child: FittedBox(
                                          fit: BoxFit.fitWidth,
                                          child: Text(
                                            'Miscellaneous',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _submitData("out");
                                      },
                                      style: ElevatedButton.styleFrom(
                                          side: BorderSide(
                                            width: 5.0,
                                            color: Theme.of(context)
                                                .primaryColorLight,
                                          ),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(40),
                                              bottomRight: Radius.circular(40),
                                            ),
                                          ),
                                          backgroundColor: Theme.of(context)
                                              .secondaryHeaderColor),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 30.0),
                                        child: FittedBox(
                                          fit: BoxFit.fitWidth,
                                          child: Text(
                                            'Clock Out',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      // Add your camera button here
                      // Add your clock button here
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void scheduleNotification(String clockOutTime) async {
    const int notificationId = 1;
    print("Accessing timezones in ClockTimePage.dart");
    Map<String, dynamic>? events =
        Provider.of<AttendanceProvider>(context, listen: false)
            .getTodayAttendance();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isReminderEnabled = prefs.getBool('isReminderEnabled') ?? false;
    print(events?['tracking'] ?? "tracking empty");
    if (!isReminderEnabled || (events?['tracking'] != null)) {
      print("why event got obj");
      return;
    }

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    print('Please clock out at $clockOutTime');
    List<String> timeParts = clockOutTime.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    int second = int.parse(timeParts[2]);

    // Get the current date
    DateTime now = DateTime.now().add(const Duration(minutes: 5));

    // Combine current date with the parsed time
    DateTime checkout =
        DateTime(now.year, now.month, now.day, hour, minute, second);
    print('Please clock out at $checkout');
    tz.TZDateTime zonedTime = tz.TZDateTime.from(checkout, tz.local);
    print("$zonedTime flutterLocalNotificationsPlugin.zonedSchedule");
    await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Clock Time Reminder',
        'Please clock out at $otTimeStr',
        zonedTime,
        const NotificationDetails(
            iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                sound: 'default',
                badgeNumber: 1,
                subtitle: 'Time to clock out!',
                threadIdentifier: 'ClockReminderThread'),
            android: AndroidNotificationDetails(
                'localClockTime', 'localClocktime',
                channelDescription: 'Reminders for clocking in and out')),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
    await prefs.setInt('scheduledNotificationId', notificationId);
  }

  void _showApplyOvertimeForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
              child: ApplyOvertimeForm(
                  defaultInTime: otTimeStr,
                  onClockTimeSuccess: widget.onClockTimeSuccess)),
        );
      },
    );
  }

// Later in your code where you decide whether to show the overtime form:
}

class ApplyOvertimeForm extends StatefulWidget {
  final String defaultInTime; // Add this
  final VoidCallback onClockTimeSuccess;

  const ApplyOvertimeForm(
      {super.key,
      required this.defaultInTime,
      required this.onClockTimeSuccess});

  @override
  _ApplyOvertimeFormState createState() => _ApplyOvertimeFormState();
}

class _ApplyOvertimeFormState extends State<ApplyOvertimeForm> {
  late TimeOfDay _selectedInTime;
  late TimeOfDay _selectedOutTime;
  bool _isNightShift = false;
  bool _isStandby = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Split the time and convert to TimeOfDay
    final splitTime =
        widget.defaultInTime.split(':').map((e) => int.parse(e)).toList();
    _selectedInTime = TimeOfDay(hour: splitTime[0], minute: splitTime[1]);

    // Use current time as default out time
    _selectedOutTime = TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'OT In Time',
            ),
            onTap: () => _selectTime(context, 'in'),
            controller:
                TextEditingController(text: _selectedInTime.format(context)),
          ),
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'OT Out Time',
            ),
            onTap: () => _selectTime(context, 'out'),
            controller:
                TextEditingController(text: _selectedOutTime.format(context)),
          ),
          CheckboxListTile(
            title: const Text('Night Shift'),
            value: _isNightShift,
            onChanged: (bool? value) {
              setState(() {
                _isNightShift = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Standby'),
            value: _isStandby,
            onChanged: (bool? value) {
              setState(() {
                _isStandby = value ?? false;
              });
            },
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      Colors.grey, // This sets the text color of the button
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Do validation here - make sure times are not null, etc.
                  // For now, just calling the API method directly
                  try {
                    DateTime now = DateTime.now();
                    DateTime otInDateTime = DateTime(now.year, now.month,
                        now.day, _selectedInTime.hour, _selectedInTime.minute);
                    DateTime otOutDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _selectedOutTime.hour,
                        _selectedOutTime.minute);

                    Map<String, dynamic>? response = await AttendantService()
                        .doClockInOutOT(otInDateTime, otOutDateTime,
                            _isNightShift, _isStandby);

                    if (response != null) {
                      widget.onClockTimeSuccess();
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Message'),
                            content: Text(response['message'].toString()),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                  Navigator.pop(context);
                                  Navigator.pop(
                                      context); // Close the ClockTimePage
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                    // You might want to show a success message here
                  } catch (e) {
                    print('Failed to apply for OT: $e');
                    // You might want to show an error message here
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectInTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedInTime,
    );
    if (pickedTime != null && pickedTime != _selectedInTime) {
      setState(() {
        _selectedInTime = pickedTime;
      });
    }
  }

  Future<void> _selectOutTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedOutTime,
    );
    if (pickedTime != null && pickedTime != _selectedOutTime) {
      setState(() {
        _selectedOutTime = pickedTime;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    if (type == 'in') {
      await _selectInTime(context);
    } else {
      await _selectOutTime(context);
    }
  }
}
