import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hr_attendant/models/leave.dart';
import 'package:hr_attendant/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:hr_attendant/services/leave_service.dart';
import 'package:image_picker/image_picker.dart';

class RequestLeavePage extends StatefulWidget {
  final Function() onLeaveRequestSuccess;

  const RequestLeavePage({super.key, required this.onLeaveRequestSuccess});
  @override
  _RequestLeavePageState createState() => _RequestLeavePageState();
}

class _RequestLeavePageState extends State<RequestLeavePage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _leaveType;
  String? _reason;
  double _days = 0;
  String halfDaySelection = "Full Day";
  String ampmSelection = "AM";
  final LeaveService _leaveService = LeaveService();
  File? _attachment;
  Map<String, String> _names = {};
  String? _selectedID;
  List<LeaveType> _leaveTypes = [];
  TextEditingController NumberofDayController = TextEditingController();
  int daysDifference = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLeaveTypes();
    _fetchData();
  }

  _fetchData() async {
    try {
      final response = await ApiService().post("/api/getDepartmentList", {});
      var data = response!['data'] as Map<String, dynamic>;
      print(data);
      setState(() {
        _names = data.map((key, value) => MapEntry(key, value.toString()));
        //_selectedID = _names.keys.first;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leave'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        DateTime initialStart = DateTime.now();
                        if (_leaveType != '100_36919') {
                          // Start date from one month ahead
                          initialStart =
                              DateTime.now().add(const Duration(days: -30));
                        } else {
                          initialStart =
                              DateTime.now().add(const Duration(days: 3));
                        }
                        print(initialStart);
                        final dateRange = await showDateRangePicker(
                          context: context,
                          firstDate: initialStart,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDateRange:
                              _startDate != null && _endDate != null
                                  ? DateTimeRange(
                                      start: _startDate!, end: _endDate!)
                                  : null,
                        );

                        if (dateRange != null) {
                          setState(() {
                            _startDate = dateRange.start;
                            _endDate = dateRange.end;
                            daysDifference =
                                _endDate!.difference(_startDate!).inDays + 1;
                            checkHalfOrFullDay();
                            NumberofDayController.text =
                                daysDifference.toString();
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _startDate == null || _endDate == null
                            ? 'Select Date Range'
                            : 'Date Range: \n${DateFormat.yMd().format(_startDate!)} - ${DateFormat.yMd().format(_endDate!)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _leaveType,
                  items: _leaveTypes
                      .map((type) => DropdownMenuItem<String>(
                            value: type.id,
                            child: Text(type.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      print(value);
                      _leaveType = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Leave Type',
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(74, 32, 31, 31), width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor, width: 2),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a leave type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                if (_leaveType == '100_49197' ||
                    _leaveType == '100_31790' ||
                    _leaveType == '100_36919|emergency') ...[
                  ElevatedButton(
                    onPressed: pickAttachment,
                    child: const Text('Upload Attachment'),
                  ),
                  if (_attachment != null)
                    Image.file(
                      File(_attachment!.path),
                      width: 150,
                      height: 150,
                    ),
                  const SizedBox(height: 16.0),
                ],
                DropdownButtonFormField<String>(
                  value: halfDaySelection,
                  items: <String>['Full Day', 'Half Day'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      halfDaySelection = newValue!;
                      checkHalfOrFullDay();
                      if (newValue == "Half Day") {
                        NumberofDayController.text = "0.5";
                      } else {
                        NumberofDayController.text = daysDifference.toString();
                      }
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Full Day/Half Day',
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(74, 32, 31, 31), width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor, width: 2),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15))),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 3, // takes 3 parts of the row space
                      child: TextFormField(
                        controller: NumberofDayController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Number of Days',
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(74, 32, 31, 31),
                                  width: 1),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15))),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15))),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number of days';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _days = double.parse(value!);
                        },
                      ),
                    ),
                    const SizedBox(
                        width: 8), // gives some space between the fields
                    if (halfDaySelection == "Half Day")
                      Expanded(
                        flex:
                            1, // takes 1 part of the row space, making it smaller than the text field
                        child: DropdownButtonFormField<String>(
                          value: ampmSelection,
                          items: <String>['AM', 'PM'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(
                                      fontSize: 14)), // smaller font size
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              ampmSelection = newValue!;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Half Day',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10.0), // reduced padding
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(74, 32, 31, 31),
                                    width: 1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15))),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(15))),
                          ),
                          isDense:
                              true, // reduces the overall size of the dropdown
                        ),
                      ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedID,
                  items: _names.entries
                      .map((entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedID = value!;
                      // you can add your code here to pass the selected name to your API
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Person to backup during absence',
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(74, 32, 31, 31), width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor, width: 2),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15))),
                  ),
                  validator: (value) {
                    /*if (value == null || value.isEmpty) {
                      return 'Please select a leave type';
                    }*/
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(74, 32, 31, 31), width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).primaryColor, width: 2),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reason';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _reason = value;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      side: BorderSide(
                        width: 5.0,
                        color: Theme.of(context).primaryColorLight,
                      ),
                      backgroundColor: Theme.of(context).secondaryHeaderColor),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      if (_startDate == null || _endDate == null) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Error'),
                            content: const Text('Please select your date'),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  // Close the dialog
                                  Navigator.pop(context);
                                  // Close the current page
                                },
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      _leaveService
                          .doSubmitLeave(
                        leaveType: _leaveType!,
                        fromDate: _startDate!,
                        toDate: _endDate!,
                        days: _days,
                        reason: _reason!,
                        takeover1_uid: _selectedID,
                        half_day: halfDaySelection == 'Half Day'
                            ? ampmSelection
                            : null,
                        attachment: (_leaveType == '100_49197' ||
                                _leaveType == '100_36919|emergency')
                            ? _attachment
                            : null,
                      )
                          .then((response) {
                        if (response != null &&
                            response['status'] == 'success') {
                          // Handle success
                          print('not here');
                          widget.onLeaveRequestSuccess();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Success'),
                                content: const Text(
                                    'Leave request submitted successfully.'),
                                actions: [
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      // Close the dialog
                                      Navigator.pop(context);
                                      // Close the current page
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          });
                        } else if (response != null &&
                            response['status'] == "error") {
                          print('should be here');
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Error'),
                              content:
                                  Text((response['data'] as List).join(', ')),
                              actions: [
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    // Close the dialog
                                    Navigator.pop(context);
                                    // Close the current page
                                  },
                                ),
                              ],
                            ),
                          );
                          // Handle error
                          print('Failed to submit leave request.');
                        } else {}
                      });
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.0),
                    child: Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> popEndDate(BuildContext context) async {
    _endDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    setState(() {});
  }

  void getLeaveTypes() async {
    ApiService api = ApiService();
    final response = await api.post('/api/getLeaveType', {});
    print(response);
    if (response != null && response['status'] == 'success') {
      setState(() {
        _leaveTypes = (response['data'] as List)
            .map((item) => LeaveType.fromJson(item))
            .toList();
      });
      print(_leaveTypes);
    }
  }

  Future<void> pickAttachment() async {
    final pickedImageSource = await showDialog<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose image source'),
              children: <Widget>[
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                  child: const Text('Take a picture'),
                ),
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                  child: const Text('Choose from gallery'),
                ),
              ],
            );
          },
        ) ??
        ImageSource.gallery;

    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: pickedImageSource);

    if (image != null) {
      setState(() {
        _attachment = File(image.path);
      });
    }
  }

  void checkHalfOrFullDay() {
    if (halfDaySelection == "Half Day" && daysDifference > 1) {
      // Alert the user to select the date range again
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid Selection'),
            content: const Text(
                'For half-day leave, the date range cannot be more than 1 day. Please select the date range again.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the alert dialog
                },
              ),
            ],
          );
        },
      );
    }
    // If the daysDifference is 1 or less, or if it's not a half-day selection, no action is needed.
  }
}
