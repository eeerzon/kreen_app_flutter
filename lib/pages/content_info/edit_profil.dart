// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/session_manager.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? langCode;
  File? pickedImage;
  final picker = ImagePicker();
  String? selectedGender;

  Map<String, dynamic> errorMessage = {};
  int errorCode = 0;

  final FocusNode firstNameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode dobFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();

  String? strAvatar, linkAvatar;
  bool isuploaded = false;
  late TextEditingController fullNameController;
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

  bool isLoading = true;
  Map<String, dynamic> bahasa = {};
  String? emailHint, phoneLabel, phoneHint, phoneError;
  String? verifEmail;

  bool showErrorBar = false;
  String errorMessageBar = "";
  bool isImage = false;

  bool _emailTouched = false;
  bool _phoneTouched = false;

  bool isConfirmLoading = false;
  bool _showError = false;

  bool _emailChanged = false;
  String _originalEmail = '';

  @override
  void initState() {
    super.initState();
    strAvatar = widget.user['photo'];
    fullNameController = TextEditingController(text: widget.user['full_name']);
    firstNameController = TextEditingController(text: widget.user['first_name']);
    lastNameController = TextEditingController(text: widget.user['last_name']);
    emailController = TextEditingController(text: widget.user['email']);
    dobController = TextEditingController(text: widget.user['dob']);
    phoneController = TextEditingController(text: widget.user['phone']);
    dob = widget.user['dob'];
    gender = widget.user['gender'] ?? '';
    companyController = TextEditingController(text: widget.user['company'] ?? '');
    jobTitleController = TextEditingController(text: widget.user['jobTitle'] ?? '');
    linkedinController = TextEditingController(text: widget.user['link_linkedin'] ?? '');
    igController = TextEditingController(text: widget.user['link_ig'] ?? '');
    twitterController = TextEditingController(text: widget.user['link_twitter'] ?? '');
    verifEmail = widget.user['verified_email'];

    selectedGender = widget.user['gender'];

    _originalEmail = widget.user['email'] ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() => langCode = code);

    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");
    
    setState(() {
      bahasa = tempbahasa;
      emailHint = bahasa['input_email'];
      phoneLabel = bahasa['nomor_hp_label'];
      phoneHint = bahasa['nomor_hp'];
      phoneError = bahasa['nomor_hp_error'];
      isLoading = false;
    });
  }

  late final genders = [
    {'label': bahasa['gender_1'], 'icon': '$baseUrl/image/male.png'},
    {'label': bahasa['gender_2'], 'icon': '$baseUrl/image/female.png'},
  ];

  bool get isSvg {
    final path = isuploaded ? strAvatar : widget.user['photo'];
    if (path == null) return false;
    return path.toLowerCase().endsWith('.svg');
  }

  bool get isHttp {
    final p = isuploaded ? strAvatar : widget.user['photo'];
    if (p == null) return false;
    return p.toLowerCase().contains("http");
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

        uploadImage(pickedImage!);
      });
    }
  }

  void _showMaxSizeAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(bahasa['alert_size_file_1']),  //"Ukuran File Terlalu Besar"
          content: Text(bahasa['alert_size_file_2']), //"Silakan pilih gambar dengan ukuran maksimal 1 MB."
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
            title: Text(bahasa['pilih_galeri']),
            onTap: () {
              Navigator.pop(context);
              pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(bahasa['pilih_kamera']),
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
    final result = await ApiService.postImage('/uploads/tmp', file: file, xLanguage: langCode);
    if (result == null || result['rc'] != 200) {
      setState(() {
        showErrorBar = true;
        errorMessage = result?['message'];

        isImage = true;
        _showError = true;
      });
      return null;
    }

    final List<dynamic> tempData = result['data'] ?? [];
    if (tempData.isEmpty) return null;

    final url = tempData[0]['url'] as String?;
    final storedAs = tempData[0]['stored_as'] as String?;

    if (!mounted) return null;
    setState(() {
      linkAvatar = url;
      strAvatar = storedAs;
      isuploaded = true;

      showErrorBar = false;
      isImage = false;
    });

    return url;
  }

  bool _validateAllForm() {
    bool isValid = true;
    FocusNode? firstErrorFocus;

    final email = emailController.text.trim();

    if (email.isEmpty || !isValidEmail(email)) {
      isValid = false;
      firstErrorFocus ??= emailFocusNode;
    }

    final phone = phoneController.text.trim();

    if (phone.isEmpty || !isValidPhone(phone)) {
      isValid = false;
      firstErrorFocus ??= phoneFocusNode;
    }

    if (selectedGender == null) {
      isValid = false;
    }

    if (dobController.text.trim().isEmpty) {
      isValid = false;
      firstErrorFocus ??= dobFocusNode;
    }

    if (!isValid && firstErrorFocus != null) {
      _scrollToFocus(firstErrorFocus);
    }

    return isValid;
  }

  void _scrollToFocus(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      node.requestFocus();

      final context = node.context;
      if (context == null) return;

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    });
  }

  void _handleSave() async {

    if (isConfirmLoading) return;

      setState(() {
        _showError = true;
      });

    final isValid = _validateAllForm();

    if (!isValid) {
      return;
    }

    setState(() {
      isConfirmLoading = true;
    });

    try {
      await saveProfile(); 
    } finally {
      if (mounted) {
        setState(() {
          isConfirmLoading = false;
        });
      }
    }
  }


  Future<void> saveProfile() async {

    String genderValue;
    final rawGender = selectedGender.toString().toLowerCase();

    if (rawGender == 'laki-laki' || rawGender == 'male') {
      genderValue = 'male';
    } else if (rawGender == 'perempuan' || rawGender == 'female') {
      genderValue = 'female';
    } else {
      genderValue = ''; // handle error
    }

    if (dobController.text.trim().isEmpty) {
        setState(() {
          _showError = true;
        });

        _scrollToFocus(dobFocusNode);
        return;
    }

    if (emailController.text.trim().isEmpty && !isValidEmail(emailController.text.trim())) {
      setState(() {
        _showError = true;
      });

      _scrollToFocus(emailFocusNode);
      return;
    }

    if (phoneController.text.trim().isEmpty && !isValidPhone(phoneController.text.trim())) {
      setState(() {
        _showError = true;
      });

      _scrollToFocus(phoneFocusNode);
      return;
    }

    if (selectedGender == null) {
      setState(() {
        _showError = true;
      });

      return;
    }
    
    String? token = await StorageService.getToken();

    final body = {
      // "first_name": "${firstNameController.text} ${lastNameController.text.isNotEmpty ? lastNameController.text : ''}",
      "first_name": fullNameController.text,
      "last_name": null,
      "email": emailController.text,
      "date_of_birth": dob,
      "phone": phoneController.text,
      "avatar": strAvatar,
      "gender": genderValue,
      "company": companyController.text.isNotEmpty ? companyController.text : null,
      "job_title": jobTitleController.text.isNotEmpty ? jobTitleController.text : null,
      "link_linkedin": linkedinController.text.isNotEmpty ? linkedinController.text : null,
      "link_ig": igController.text.isNotEmpty ? igController.text : null,
      "link_twitter": twitterController.text.isNotEmpty ? twitterController.text : null,
    };

    final resultSimpan = await ApiService.postSetProfil('$baseapiUrl/setting/update-profile',token: token, body: body, xLanguage: langCode);

    if (resultSimpan?['rc'] == 200) {
      await StorageService.setUser(
        id: widget.user['id'],
        // first_name: "${firstNameController.text} ${lastNameController.text.isNotEmpty ? lastNameController.text : ''}",
        first_name: fullNameController.text,
        last_name: lastNameController.text.isNotEmpty ? lastNameController.text : null, 
        phone: phoneController.text, 
        email: emailController.text, 
        photo: strAvatar,
        DOB: dob,
        gender: genderValue,
        company: companyController.text.isNotEmpty ? companyController.text : null,
        jobTitle: jobTitleController.text.isNotEmpty ? jobTitleController.text : null,
        link_linkedin: linkedinController.text.isNotEmpty ? linkedinController.text : null,
        link_ig: igController.text.isNotEmpty ? igController.text : null,
        link_twitter: twitterController.text.isNotEmpty ? twitterController.text : null,
        verifEmail: _emailChanged ? '0' : (verifEmail ?? '0'),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bahasa['sukses_info_profil'])), //"Profil berhasil diubah"
      );

      showErrorBar = false;
      isImage = false;

      // Navigator.pushAndRemoveUntil(
      //   context, 
      //   MaterialPageRoute(builder: (context) => HomePage()), 
      //   (route) => false
      // );

      Navigator.pop(context, true);
      
    } else if (resultSimpan?['rc'] == 422) {
      setState(() {
        showErrorBar = true;
        errorCode = resultSimpan?['rc'] ?? 0;
        errorMessage = resultSimpan?['data'] ?? {};
        errorMessageBar = resultSimpan?['message'];

        isImage = false;
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
    } else if (resultSimpan?['rc'] == 401) {
      setState(() {
        showErrorBar = true;
        errorCode = resultSimpan?['rc'] ?? 0;
        errorMessageBar = resultSimpan?['message'];
      });

      final loginMethod = await StorageService.getLoginMethod();

      if (loginMethod == 'google') {
        final googleSignIn = GoogleSignIn();

        await googleSignIn.disconnect();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      }

      await StorageService.clearUser();
      await StorageService.clearToken();
      await StorageService.clearLoginMethod();
      
      AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        animType: AnimType.topSlide,
        dismissOnTouchOutside: false,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text(
                bahasa['session_expired'] ?? "",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                "$errorMessageBar\n\n${bahasa['login_lagi']}",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              /// BUTTON LOGIN
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: Text(
                    bahasa['login'] ?? "Login",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// BUTTON LOGIN SEBAGAI TAMU
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      SessionManager.isGuest = true;
                      SessionManager.checkingUserModalShown = true;
                    });

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    bahasa['guest_login'] ?? "Lanjut sebagai tamu",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).show();
    } else {
      setState(() {
        showErrorBar = true;
        errorCode = resultSimpan?['rc'] ?? 0;
        errorMessageBar = resultSimpan?['message'];

        isImage = false;
      });
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
      helpText: bahasa['pilih_dob'],
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
      return DateFormat(formatDateId, "id_ID").format(date);
    } else {
      final datePart = DateFormat(formatDateEn, "en_US").format(date);

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
          final datePart = DateFormat(formatDateId, "id_ID").format(date);
          formattedDate = datePart;
          dobController.text = formattedDate;
        } else {
          // Bahasa Inggris
          final datePart = DateFormat(formatDateEn, "en_US").format(date);

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

    // selectedGender = gender;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text('Edit ${bahasa['profil']}'),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Stack(
          children: [
            isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.red,))
              : SingleChildScrollView(
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
                                  child: pickedImage != null
                                    ? Image.file(
                                        pickedImage!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : _buildNetworkAvatar(),
                                ),
                              ),

                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () {
                                    showPickSourceDialog();
                                  },
                                  borderRadius: BorderRadius.circular(8),
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
                              bahasa['informasi_utama'] , //'Informasi Utama',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                          SizedBox(height: 10,),
                          Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(
                              bahasa['nama_lengkap_label']
                            ),
                          ),
                          SizedBox(height: 8,),
                          TextField(
                            focusNode: firstNameFocusNode,
                            controller: fullNameController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[a-zA-Z\s]"),
                              ),
                              NameInputFormatter(),
                            ],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: bahasa['nama_depan_hint'],
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          if (errorCode == 422 && errorMessage.containsKey('first_name')) ... [
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                                child: Text(
                                  errorMessage['first_name'][0],
                                  style: TextStyle(color: Colors.red[900], fontSize: 12),
                                ),
                              )
                            )
                          ],

                          // SizedBox(height: 20,),
                          // Align(
                          //   alignment: AlignmentGeometry.centerLeft,
                          //   child: Text(
                          //     bahasa['nama_belakang_label']
                          //   ),
                          // ),
                          // SizedBox(height: 8,),
                          // TextField(
                          //   controller: lastNameController,
                          //   onChanged: (_) => setState(() {}),
                          //   inputFormatters: [
                          //     FilteringTextInputFormatter.allow(
                          //       RegExp(r"[a-zA-Z\s]"),
                          //     ),
                          //     NameInputFormatter(),
                          //   ],
                          //   decoration: InputDecoration(
                          //     hintText: bahasa['nama_belakang_hint'],
                          //     hintStyle: TextStyle(color: Colors.grey.shade400),
                          //     border: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     filled: true,
                          //     fillColor: Colors.white,
                          //   ),
                          // ),

                          SizedBox(height: 20,),
                          Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(
                              bahasa['dob_label'],
                            ),
                          ),
                          SizedBox(height: 8,),
                          TextField(
                            focusNode: dobFocusNode,
                            controller: dobController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              hintText: bahasa['pilih_dob'],
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                          ),
                          if (_showError && dobController.text.isEmpty)
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 0, 0), //left, top, right, bottom
                                child: Text(
                                  bahasa['dob_required'],
                                  style: TextStyle(
                                    color: Colors.red[900],
                                    fontSize: 12
                                  ),
                                ),
                              ),
                            ),
                          // if (errorCode == 422 && errorMessage.containsKey('date_of_birth')) ... [
                          //   Align(
                          //     alignment: AlignmentGeometry.centerLeft,
                          //     child: Padding(
                          //       padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                          //       child: Text(
                          //         errorMessage['date_of_birth'][0],
                          //         style: TextStyle(color: Colors.red[900], fontSize: 12),
                          //       ),
                          //     )
                          //   )
                          // ],

                          SizedBox(height: 20,),
                          Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(
                              bahasa['gender_label'], //'Jenis Kelamin'
                            ),
                          ),
                          SizedBox(height: 8,),
                          Row(
                            children: List.generate(genders.length, (index) {
                              final item = genders[index];
                              final isSelectedGender =
                                (selectedGender.toString().toLowerCase() == 'male'
                                        ? bahasa['gender_1']
                                        : bahasa['gender_2'])
                                    .toString()
                                    .toLowerCase() ==
                                item['label'].toString().toLowerCase();

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedGender = item['label'].toString().toLowerCase() ==
                                            bahasa['gender_1'].toString().toLowerCase()
                                        ? 'male'
                                        : 'female';

                                      gender = item['label'].toString().toLowerCase() ==
                                            bahasa['gender_1'].toString().toLowerCase()
                                        ? 'male'
                                        : 'female';
                                    });
                                  },
                                  child: Container(
                                    height: 120,
                                    margin: EdgeInsets.only(
                                      right: index == 0 ? 8 : 0,
                                      left: index == 1 ? 8 : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
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
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/img_broken.jpg',
                                              width: 50,
                                              height: 50,
                                            );
                                          },
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
                              bahasa['company_label'], //'Perusahaan'
                            ),
                          ),
                          SizedBox(height: 8,),
                          TextField(
                            controller: companyController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: bahasa['company_hint'],
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),

                          SizedBox(height: 20,),
                          Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(
                              bahasa['job_label'], //'Jabatan'
                            ),
                          ),
                          SizedBox(height: 8,),
                          TextField(
                            controller: jobTitleController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: bahasa['job_hint'],
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),

                          SizedBox(height: 20,),
                          Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(
                              bahasa['informasi_akun'], //']'Informasi Akun',
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
                            onChanged: (value) => setState(() {
                              if (!_emailTouched) {
                                setState(() {
                                  _emailTouched = true;
                                });
                              } else {
                                setState(() {
                                  
                                });
                              }

                              setState(() {
                                _emailChanged = value.trim() != _originalEmail.trim();
                              });
                            }),
                            decoration: InputDecoration(
                              hintText: emailHint,
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),

                          if (_emailTouched && !isValidEmail(emailController.text))
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                                child: Text(
                                  bahasa['error_email_1'],
                                  style: TextStyle(color: Colors.red[900], fontSize: 12),
                                ),
                              ),
                            ),

                          if (errorCode == 422 && errorMessage.containsKey('email')) ... [
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                                child: Text(
                                  langCode == "en"
                                    ? translateError(errorMessage['email'][0], langCode)
                                    : errorMessage['email'][0],
                                  style: TextStyle(color: Colors.red[900], fontSize: 12),
                                ),
                              ),
                            )
                          ],

                          if (verifEmail == "0" || _emailChanged) ... [
                            SizedBox(height: 4,),
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                                child: Text(
                                  bahasa['verified_email'], //"Email kamu belum diverifikasi. ",
                                  style: TextStyle(color: Colors.red[900], fontSize: 12),
                                )
                              ),
                            )
                          ] else ...[
                            SizedBox(height: 4,),
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      bahasa['verified_email_done'] ?? "Email kamu sudah terverifikasi. ", //"Email kamu sudah terverifikasi. ",
                                      style: TextStyle(color: Colors.green[900], fontSize: 12),
                                    ),

                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: Colors.green[900],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],

                          SizedBox(height: 20,),
                          Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(
                              phoneLabel!
                            ),
                          ),
                          SizedBox(height: 8,),
                          TextField(
                            focusNode: phoneFocusNode,
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {
                              if (!_phoneTouched) {
                                setState(() => _phoneTouched = true);
                              } else {
                                setState(() {});
                              }
                            }),
                            decoration: InputDecoration(
                              hintText: phoneHint,
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),

                          if ((_phoneTouched && !isValidPhone(phoneController.text)) || !isValidPhone(phoneController.text))
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                                child: Text(
                                  phoneError!,
                                  style: TextStyle(color: Colors.red[900], fontSize: 12),
                                ),
                              ),
                            ),

                          if (errorCode == 422 && errorMessage.containsKey('phone')) ... [
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                                child: Text(
                                  errorMessage['phone'][0],
                                  style: TextStyle(color: Colors.red[900], fontSize: 12),
                                ),
                              )
                            )
                          ],

                          SizedBox(height: 20,),
                          Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(
                              bahasa['media_sosial'], //'Media Sosial',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 10,),
                          Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(
                              bahasa['uname_linkedin_label'],
                            ),
                          ),
                          SizedBox(height: 8,),
                          TextField(
                            controller: linkedinController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: bahasa['uname_linkedin_hint'],
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
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
                              bahasa['uname_instagram_label'],
                            ),
                          ),
                          SizedBox(height: 8,),
                          TextField(
                            controller: igController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: bahasa['uname_instagram_hint'],
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
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
                              bahasa['uname_twitter_label'],
                            ),
                          ),
                          SizedBox(height: 8,),
                          TextField(
                            controller: twitterController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: bahasa['uname_twitter_hint'],
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
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
                            // onTap: () async {
                            //   await saveProfile();
                            //   // Navigator.pop(context, true);
                            // },
                            onTap: isConfirmLoading
                              ? null
                              : _handleSave,
                            child: Container(
                              height: 48,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isConfirmLoading
                                  ? Colors.grey.shade400 
                                  : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: isConfirmLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    bahasa['simpan'],
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                            ),
                          ),

                          SizedBox(height: 40,),
                        ],
                      ),
                    ),
                  )
                ),

            GlobalErrorBar(
              visible: showErrorBar, 
              message: errorMessageBar, 
              onRetry: () {
                isImage
                  ? uploadImage(pickedImage!)
                  : saveProfile();
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkAvatar() {
    final photo = widget.user['photo'];

    if (photo == null) {
      return Image.network(
        "$baseUrl/noimage_finalis.png",
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    }

    final imageUrl = isuploaded && linkAvatar != null
        ? linkAvatar!
        : isHttp
            ? photo
            : '$baseUrl/user/$photo';

    if (isSvg) {
      return SvgPicture.network(
        imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      imageUrl,
      width: 120,
      height: 120,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/img_broken.jpg',
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      },
    );
  }



  final Map<String, String> errorTranslationMap = {
    'Email sudah terdaftar': 'Email is already registered',

    'Email harus berupa email yang valid': 'Email must be a valid email',

    'Password minimal 8 karakter': 'Password must be at least 8 characters',

    'Password harus mengandung setidaknya satu huruf dan satu angka':
        'Password must contain at least one letter and one number',

    'Password tidak cocok': 'Password does not match',
  };

  String translateError(String message, String? langCode) {
    if (langCode == 'id') {
      return message;
    }

    final normalized = message.toLowerCase().trim();

    for (final entry in errorTranslationMap.entries) {
      final key = entry.key.toLowerCase().trim();

      if (normalized.contains(key)) {
        return entry.value;
      }
    }

    return message;
  }
}

class NameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Hapus spasi di awal & akhir
    text = text.trim();

    // Ubah multiple space jadi satu
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

