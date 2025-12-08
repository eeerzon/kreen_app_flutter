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
  String? selectedGender;

  Map<String, dynamic> errorMessage = {};
  int errorCode = 0;

  final FocusNode firstNameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode dobFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();

  final genders = [
      {'label': 'Laki-laki', 'icon': '$baseUrl/image/male.png'},
      {'label': 'Perempuan', 'icon': '$baseUrl/image/female.png'},
    ];

  String? strAvatar, linkAvatar;
  bool isuploaded = false;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late TextEditingController phoneController;
  String? dob, gender;
  late TextEditingController companyController;
  late TextEditingController jobTitleController;
  late TextEditingController linkedinController;
  late TextEditingController igController;
  late TextEditingController twitterController;

  @override
  void initState() {
    super.initState();
    strAvatar = widget.user['photo'];
    firstNameController = TextEditingController(text: widget.user['first_name']);
    lastNameController = TextEditingController(text: widget.user['last_name']);
    emailController = TextEditingController(text: widget.user['email']);
    dobController = TextEditingController(text: widget.user['dob']);
    phoneController = TextEditingController(text: widget.user['phone']);
    dob = widget.user['dob'];
    gender = widget.user['gender'] ?? '';

    if (gender!.isNotEmpty) {
      selectedGender = gender?.toLowerCase() == 'male' ? 'Laki-laki' : 'Perempuan';
    }
    companyController = TextEditingController(text: widget.user['company'] ?? '');
    jobTitleController = TextEditingController(text: widget.user['jobTitle'] ?? '');
    linkedinController = TextEditingController(text: widget.user['link_linkedin'] ?? '');
    igController = TextEditingController(text: widget.user['link_ig'] ?? '');
    twitterController = TextEditingController(text: widget.user['link_twitter'] ?? '');
  }

  bool get isSvg {
    final path = isuploaded ? strAvatar : widget.user['photo'];
    if (path == null) return false;
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
  }


  Future<void> saveProfile() async {
    if (selectedGender == 'Laki-laki') {
      selectedGender = 'male';
    } else if (selectedGender == 'Perempuan') {
      selectedGender = 'female';
    }
    String? token = await StorageService.getToken();

    final body = {
      "first_name": firstNameController.text,
      "last_name": lastNameController.text.isNotEmpty ? lastNameController.text : null,
      "email": emailController.text,
      "date_of_birth": dob,
      "phone": phoneController.text,
      "avatar": strAvatar,
      "gender": selectedGender,
      "company": companyController.text.isNotEmpty ? companyController.text : null,
      "job_title": jobTitleController.text.isNotEmpty ? jobTitleController.text : null,
      "link_linkedin": linkedinController.text.isNotEmpty ? linkedinController.text : null,
      "link_ig": igController.text.isNotEmpty ? igController.text : null,
      "link_twitter": twitterController.text.isNotEmpty ? twitterController.text : null,
    };
    
    final resultSimpan = await ApiService.postSetProfil('$baseapiUrl/setting/update-profile',token: token, body: body);

    if (resultSimpan?['rc'] == 200) {
      await StorageService.setUser(
        first_name: firstNameController.text, 
        last_name: lastNameController.text.isNotEmpty ? lastNameController.text : null, 
        phone: phoneController.text, 
        email: emailController.text, 
        photo: strAvatar,
        DOB: dob,
        gender: selectedGender,
        company: companyController.text.isNotEmpty ? companyController.text : null,
        jobTitle: jobTitleController.text.isNotEmpty ? jobTitleController.text : null,
        link_linkedin: linkedinController.text.isNotEmpty ? linkedinController.text : null,
        link_ig: igController.text.isNotEmpty ? igController.text : null,
        link_twitter: twitterController.text.isNotEmpty ? twitterController.text : null
      );

      Navigator.pop(context, true);
    } else {
      setState(() {
        errorCode = resultSimpan?['rc'] ?? 0;
        errorMessage = resultSimpan?['data'] ?? {};
      });

      if (resultSimpan?['data'].containsKey('first_name')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          firstNameFocusNode.requestFocus();
        });
      }

      if (resultSimpan?['data'].containsKey('email')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          emailFocusNode.requestFocus();
        });
      }

      if (resultSimpan?['data'].containsKey('date_of_birth')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          dobFocusNode.requestFocus();
        });
      }

      if (resultSimpan?['data'].containsKey('phone')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          phoneFocusNode.requestFocus();
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    if (widget.user['dob'] != null) {
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
    
    if (widget.user['dob'] != null) {
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
                        child: widget.user['photo'] != null
                        ? isSvg
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
                              )
                        : Image.network(
                          "$baseUrl/noimage_finalis.png",
                          width: 120, 
                          height: 120, fit: 
                          BoxFit.cover,
                        )
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
                    'Informasi Utama',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(height: 10,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Nama depan'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  focusNode: firstNameFocusNode,
                  controller: firstNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama depan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                if (errorCode == 422 && errorMessage.containsKey('first_name')) ... [
                  SizedBox(height: 4,),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      errorMessage['first_name'][0],
                      style: TextStyle(color: Colors.red),
                    )
                  )
                ],

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Nama belakang'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  controller: lastNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama belakang',
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
                SizedBox(height: 8,),
                TextField(
                  focusNode: dobFocusNode,
                  controller: dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: InputDecoration(
                    hintText: 'Pilih tanggal lahir',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
                if (errorCode == 422 && errorMessage.containsKey('date_of_birth')) ... [
                  SizedBox(height: 4,),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      errorMessage['date_of_birth'][0],
                      style: TextStyle(color: Colors.red),
                    )
                  )
                ],

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Jenis Kelamin'
                  ),
                ),
                SizedBox(height: 8,),
                Row(
                  children: List.generate(genders.length, (index) {
                    final item = genders[index];
                    final isSelectedGender = selectedGender == item['label'];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedGender = item['label'];
                            gender = item['label'];
                          });
                        },
                        child: Container(
                          height: 120,
                          margin: EdgeInsets.only(
                            right: index == 0 ? 8 : 0,
                            left: index == 1 ? 8 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: isSelectedGender ? Colors.green.withOpacity(0.1) : Colors.white,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                item['icon'] as String,
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['label']!,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: 10,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Perusahaan'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  controller: companyController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama perusahaan',
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
                    'Jabatan'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  controller: jobTitleController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Masukkan jabatan',
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
                    'Informasi Akun',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Email'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  focusNode: emailFocusNode,
                  controller: emailController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Masukkan Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                if (errorCode == 422 && errorMessage.containsKey('email')) ... [
                  SizedBox(height: 4,),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      errorMessage['email'][0],
                      style: TextStyle(color: Colors.red),
                    )
                  )
                ],

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'No Phone'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  focusNode: phoneFocusNode,
                  controller: phoneController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Masukkan No Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                if (errorCode == 422 && errorMessage.containsKey('phone')) ... [
                  SizedBox(height: 4,),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: Text(
                      errorMessage['phone'][0],
                      style: TextStyle(color: Colors.red),
                    )
                  )
                ],

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Media Sosial',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Username Linkedin'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  controller: linkedinController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'masukkan username Linkedin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,

                    prefixIcon: !linkedinController.text.contains("https")
                      ? Container(
                          width: 125,
                          padding: EdgeInsets.only(left: 16, right: 0),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "linkedin.com/in/",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : null,

                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                  ),
                ),

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Username Instagram'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  controller: igController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'masukkan username Instagram',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,

                    prefixIcon: !igController.text.contains("https")
                      ? Container(
                          width: 125,
                          padding: EdgeInsets.only(left: 16, right: 0),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "instagram.com/",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : null,

                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                  ),
                ),

                SizedBox(height: 20,),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Username Twitter'
                  ),
                ),
                SizedBox(height: 8,),
                TextField(
                  controller: twitterController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'masukkan username Twitter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,

                    prefixIcon: !twitterController.text.contains("https")
                      ? Container(
                          width: 100,
                          padding: EdgeInsets.only(left: 16, right: 0),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "twitter.com/",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : null,

                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                  ),
                ),
                
                SizedBox(height: 30,),
                InkWell(
                  onTap: () async {
                    await saveProfile();
                    // Navigator.pop(context, true);
                  },
                  child: Container(
                    height: 48,
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

                SizedBox(height: 40,),
              ],
            ),
          ),
        )
      )
    );
  }
}
