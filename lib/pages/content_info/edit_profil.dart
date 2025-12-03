// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String langCode = 'id';
  File? pickedImage;
  final picker = ImagePicker();

  String? strAvatar, linkAvatar;
  bool isuploaded = false;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late TextEditingController phoneController;
  String? dob;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.user['first_name']);
    lastNameController = TextEditingController(text: widget.user['last_name']);
    emailController = TextEditingController(text: widget.user['email']);
    dobController = TextEditingController(text: widget.user['dob']);
    phoneController = TextEditingController(text: widget.user['phone']);
    dob = widget.user['dob'];
  }

  bool get isSvg {
    final path = isuploaded ? strAvatar : widget.user['photo'];
    return path.toLowerCase().endsWith('.svg');
  }
  
  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image != null) {
      final file = File(image.path);
      final fileSize = await file.length();

      if (fileSize > 1000000) {
        _showMaxSizeAlert();
        return;
      }

      setState(() {
        pickedImage = File(image.path);

        uploadImage(pickedImage!);
      });
    }
  }

  Future<void> pickFromCamera() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (image != null) {
      final file = File(image.path);
      final fileSize = await file.length();

      if (fileSize > 1000000) {
        _showMaxSizeAlert();
        return;
      }
      setState(() {
        pickedImage = File(image.path);
      });
    }
  }

  void _showMaxSizeAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ukuran File Terlalu Besar"),
          content: const Text("Silakan pilih gambar dengan ukuran maksimal 1 MB."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showPickSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Pilih dari Galeri"),
            onTap: () {
              Navigator.pop(context);
              pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Ambil dari Kamera"),
            onTap: () {
              Navigator.pop(context);
              pickFromCamera();
            },
          ),
        ],
      ),
    );
  }

  Future<String?> uploadImage(File file) async {
    try {
      final result = await ApiService.postImage('/uploads/tmp', file: file);

      final List<dynamic> tempData = result?['data'] ?? [];
      if (tempData.isEmpty) return null;

      final url = tempData[0]['url'] as String?;
      final storedAs = tempData[0]['stored_as'] as String?;

      setState(() {
        linkAvatar = url;
        strAvatar = storedAs;
        isuploaded = true;
      });

      return url;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }


  Future<void> saveProfile() async {
    String? token = await StorageService.getToken();

    final body = {
      "first_name": firstNameController.text,
      "last_name": lastNameController.text,
      "email": emailController.text,
      "date_of_birth": dob,
      "phone": phoneController.text,
      "avatar": strAvatar
    };
    
    if (strAvatar != null) {
      final resultSimpan = await ApiService.postSetProfil('/setting/update-profile',token: token, body: body);

      if (resultSimpan?['rc'] == 200) {
        await StorageService.setUser(
          first_name: firstNameController.text, 
          last_name: lastNameController.text, 
          phone: phoneController.text, 
          email: emailController.text, 
          photo: strAvatar!,
          DOB: dob!
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    if (widget.user['dob'].isNotEmpty) {
      try {
        initialDate = DateTime.parse(widget.user['dob']);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Lahir',
    );

    if (picked != null) {
      setState(() {
        widget.user['dob'] = picked.toIso8601String().split('T').first;
        dobController.text = _formatDate(picked);
        dob = picked.toIso8601String().split('T').first;
      });
    }
  }

  String _formatDate(DateTime date) {
    if (langCode == 'id') {
      return DateFormat("dd MMMM yyyy", "id_ID").format(date);
    } else {
      final datePart = DateFormat("MMMM d yyyy", "en_US").format(date);

      // tambahkan suffix
      final day = date.day;
      String suffix = 'th';
      if (day % 10 == 1 && day != 11) {
        suffix = 'st';
      } else if (day % 10 == 2 && day != 12) {
        suffix = 'nd';
      } else if (day % 10 == 3 && day != 13) {
        suffix = 'rd';
      }

      final datePartWithSuffix = datePart.replaceFirst('$day', '$day$suffix');
      return datePartWithSuffix;
    }
  }


  @override
  Widget build(BuildContext context) {
    String formattedDate = '-';
    
    if (widget.user['dob'].isNotEmpty) {
      try {
        // parsing string ke DateTime
        final date = DateTime.parse(widget.user['dob']); // pastikan format ISO (yyyy-MM-dd)
        if (langCode == 'id') {
          // Bahasa Indonesia
          final datePart = DateFormat("dd MMMM yyyy", "id_ID").format(date);
          formattedDate = datePart;
          dobController.text = formattedDate;
        } else {
          // Bahasa Inggris
          final datePart = DateFormat("MMMM d yyyy", "en_US").format(date);

          // tambahkan suffix (1st, 2nd, 3rd, 4th...)
          final day = date.day;
          String suffix = 'th';
          if (day % 10 == 1 && day != 11) {
            suffix = 'st';
          } else if (day % 10 == 2 && day != 12) {
            suffix = 'nd';
          }else if (day % 10 == 3 && day != 13) {
            suffix = 'rd';
          }

          final datePartWithSuffix = datePart.replaceFirst('$day', '$day$suffix');
          formattedDate = datePartWithSuffix;
          dobController.text = formattedDate;
        }
      } catch (e) {
        formattedDate = '-';
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text('Edit Profil'),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        child: Container(
          // height: MediaQuery.of(context).size.height,
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      child: ClipOval(
                        child: isSvg
                          ? SvgPicture.network(
                              isuploaded
                                  ? linkAvatar!
                                  : '$baseUrl/user/${widget.user['photo']}',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              isuploaded
                                  ? linkAvatar!
                                  : '$baseUrl/user/${widget.user['photo']}',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          showPickSourceDialog();
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300,),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Nama depan'
                  ),
                ),
                TextField(
                  controller: firstNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Nama Depan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Nama belakang'
                  ),
                ),
                TextField(
                  controller: lastNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Nama Belakang',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Email'
                  ),
                ),
                TextField(
                  controller: emailController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Tanggal Lahir'
                  ),
                ),
                TextField(
                  controller: dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: InputDecoration(
                    hintText: 'Tanggal Lahir',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'No Phone'
                  ),
                ),
                TextField(
                  controller: phoneController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'No Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                
                SizedBox(height: 20,),
                InkWell(
                  onTap: () async {
                    await saveProfile();
                    Navigator.pop(context, true);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Simpan",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                SizedBox(height: 20,),
              ],
            ),
          ),
        )
      )
    );
  }
}
