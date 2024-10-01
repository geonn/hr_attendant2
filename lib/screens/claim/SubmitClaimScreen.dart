import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hr_attendant/models/claimType.dart';
import 'package:hr_attendant/provider/claimProvider.dart';
import 'package:hr_attendant/services/claim_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class SubmitClaimScreen extends StatefulWidget {
  const SubmitClaimScreen({super.key});

  @override
  _SubmitClaimScreenState createState() => _SubmitClaimScreenState();
}

class _SubmitClaimScreenState extends State<SubmitClaimScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _category = '';
  DateTime _visitDate = DateTime.now();
  String _receiptNo = '';
  String _providerName = '';
  double _amount = 0.0;
  String _remark = '';
  File? _file;

  var _selectedClaimType;
  final picker = ImagePicker();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Provider.of<ClaimProvider>(context, listen: false).fetchClaimTypes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Claim'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  onPressed: _pickDate,
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                        'Visit Date: ${DateFormat('yyyy-MM-dd').format(_visitDate)}'),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Receipt No',
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
                  onSaved: (value) {
                    _receiptNo = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Receipt No. Cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                Consumer<ClaimProvider>(
                  builder: (context, claimProvider, child) {
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category',
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
                      value: _selectedClaimType,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Category cannot be empty';
                        }
                        return null;
                      },
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedClaimType = newValue!;
                          _category = newValue;
                        });
                      },
                      items: claimProvider.claimTypes
                          .map<DropdownMenuItem<String>>((ClaimType value) {
                        return DropdownMenuItem<String>(
                          value: value.id,
                          child: Text(value.name),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Provider Name',
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
                  onSaved: (value) {
                    _providerName = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Provider cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Amount',
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
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  onSaved: (value) {
                    _amount = double.parse(value!);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Remark',
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
                  onSaved: (value) {
                    _remark = value!;
                  },
                ),
                const SizedBox(height: 16.0),
                // Image picker button
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_a_photo),
                  onPressed: _showImagePickerOptions,
                  label: const Text('Attach Receipt'),
                ),
                if (_file != null)
                  ListTile(
                    subtitle: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width:
                                  5.0, // You can set the width to your liking
                            ),
                            borderRadius: BorderRadius.circular(
                                5), // You can set the radius to your liking
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.file(_file!),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          child: Container(
                            color: Colors.white,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text("Attachment"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                /*SizedBox(
                    height: 200, // Adjust as needed
                    width: 200, // Adjust as needed
                    child: _file != null
                        ? Image.file(
                            _file!,
                            fit: BoxFit.cover,
                          )
                        : Container()),*/
                // Add other form fields in similar way
                // When adding the file field, use FilePicker or ImagePicker package to pick the file
                // After adding all fields, add a RaisedButton for form submission
                const SizedBox(height: 16.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      side: BorderSide(
                        width: 5.0,
                        color: Theme.of(context).primaryColorLight,
                      ),
                      backgroundColor: Theme.of(context).secondaryHeaderColor),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // If the form is valid, display a Snackbar and submit the form
                      if (_file == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please upload your attachment')),
                        );
                        return;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Processing Data')),
                        );
                      }
                      _formKey.currentState!.save();
                      final ClaimService claimService = ClaimService();

                      try {
                        print('aaaa');
                        final response = await claimService.submitClaim(
                          category: _category,
                          visitDate: _visitDate.toString(),
                          receiptNo: _receiptNo,
                          providerName: _providerName,
                          amount: _amount.toString(),
                          remark: _remark,
                          file: _file!,
                        );
                        Logger().d(response);
                        if (response != null) {
                          if (response['status'] == "success") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Claim submitted')),
                            );
                          } else if (response['status'] == 'error') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response['data'])),
                            );
                          }
                        }
                        /*await Provider.of<ClaimProvider>(context, listen: false)
                            .submitClaim(
                                _category,
                                _visitDate.toString(),
                                _receiptNo,
                                _providerName,
                                _amount,
                                _remark,
                                _file!);*/
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Claim submitted')),
                        );
                        Navigator.of(context).pop();
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                      }
                    } else {}
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.0),
                    child: Text('Submit Claim'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
      });
    } else {
      print('No image selected.');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  // Added for showing date picker and setting _visitDate
  _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (date != null) {
      setState(() {
        _visitDate = date;
      });
    }
  }
}
