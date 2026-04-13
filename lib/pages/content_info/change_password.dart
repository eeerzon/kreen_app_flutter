// ignore_for_file: prefer_interpolation_to_compose_strings, use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
import 'package:kreen_app_flutter/helper/session_manager.dart';
import 'package:kreen_app_flutter/pages/home_page.dart';
import 'package:kreen_app_flutter/pages/login_page.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class ChangePassword extends StatefulWidget {

  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePasswordCurrent = true;
  bool _obscurePasswordNew = true;
  bool _obscurePasswordConfirm = true;

  final FocusNode _currentPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool get _isFormFilled =>
      _currentPasswordController.text.isNotEmpty &&
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  Map<String, dynamic> errorMessage = {};
  String errorMessage500 = '';
  int errorCode = 0;
  bool showErrorBar= false;

  bool isLoading = true;
  bool _lockCurrentPasswordField = false;
  bool _lockNewPasswordField = false;
  bool _lockConfirmPasswordField = false;
  
  String? newPasswordError;
  String? confirmPasswordError;

  String? langCode;
  Map<String, dynamic> bahasa = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();
    setState(() => langCode = code);

    final tempbahasa = await LangService.getJsonData(langCode!, 'bahasa');
    setState(() {
      bahasa = tempbahasa;

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(bahasa['change_password'] ?? ""),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Stack(
          children: [
            isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.red,),)
              : SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    padding: kGlobalPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bahasa['pengaturan_password'], //'Pengaturan Kata Sandi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),

                        SizedBox(height: 20),
                        Text(
                          bahasa['pengaturan_password_desc'], //'Kata sandi baru tidak boleh sama dengan kata sandi sebelumnya.'
                        ),

                        SizedBox(height: 20),
                        Text(
                          bahasa['old_password_label'], //'Password Lama',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 8),
                        TextField(
                          controller: _currentPasswordController,
                          focusNode: _currentPasswordFocus,
                          readOnly: _lockCurrentPasswordField,
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (_) => setState(() {}),
                          obscureText: _obscurePasswordCurrent,
                          decoration: InputDecoration(
                            hintText: bahasa['old_password_hint'], //'Masukkan kata sandi lama',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey, width: 2),
                            ),
                            suffixIcon: InkWell(
                              onTap: () async {
                                _unfocusAll(context);
                                setState(() {
                                  _lockCurrentPasswordField = true;
                                  _obscurePasswordCurrent = !_obscurePasswordCurrent;
                                });

                                await Future.delayed(const Duration(milliseconds: 30));

                                setState(() {
                                  _lockCurrentPasswordField = false;
                                });
                              },
                              child: Icon(
                                _obscurePasswordCurrent
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              ),
                            )
                          ),
                        ),
                        if (errorCode == 500) ... [
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                            child: Text(
                              errorMessage500,
                              style: TextStyle(color: Colors.red[900], fontSize: 12),
                            ),
                          ),
                        ]
                        else if (errorCode == 422) ... [
                          if (errorMessage['current_password'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var err in errorMessage['current_password'])
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                                    child: Text(
                                      translateError(err.toString(), langCode),
                                      style: TextStyle(color: Colors.red[900], fontSize: 12),
                                    ),
                                  ),
                              ],
                            )
                        ],

                        SizedBox(height: 20),
                        Text(
                          bahasa['new_password_label'], //'Password Baru',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 8),
                        TextField(
                          controller: _newPasswordController,
                          focusNode: _newPasswordFocus,
                          readOnly: _lockNewPasswordField,
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (_) => setState(() {}),
                          obscureText: _obscurePasswordNew,
                          decoration: InputDecoration(
                            hintText: bahasa['new_password_hint'], //'Masukkan kata sandi baru',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey, width: 2),
                            ),
                            suffixIcon: InkWell(
                              onTap: () async {
                                _unfocusAll(context);
                                setState(() {
                                  _lockNewPasswordField = true;
                                  _obscurePasswordNew = !_obscurePasswordNew;
                                });

                                await Future.delayed(const Duration(milliseconds: 30));

                                setState(() {
                                  _lockNewPasswordField = false;
                                });
                              },
                              child: Icon(
                                _obscurePasswordNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              ),
                            )
                          ),
                        ),
                        if (errorCode == 500) ... [
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                            child: Text(
                              errorMessage500,
                              style: TextStyle(color: Colors.red[900], fontSize: 12),
                            ),
                          ),
                        ]
                        else if (errorCode == 422) ... [
                          if (errorMessage['password'] != null && (errorMessage['password'] as List).any((e) => e.toString().contains('New')))
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                              child: Text(
                                newPasswordError ?? '',
                                style: TextStyle(color: Colors.red[900], fontSize: 12),
                              ),
                            ),
                        ],

                        SizedBox(height: 20),
                        Text(
                          bahasa['konfirmasi_password_label'], //']'Konfirmasi Kata Sandi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 8),
                        TextField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          readOnly: _lockConfirmPasswordField,
                          keyboardType: TextInputType.visiblePassword,
                          onChanged: (_) => setState(() {}),
                          obscureText: _obscurePasswordConfirm,
                          decoration: InputDecoration(
                            hintText: bahasa['konfirmasi_password'], //'konfirmasi kata sandi',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey, width: 2),
                            ),
                            suffixIcon: InkWell(
                              onTap: () async {
                                _unfocusAll(context);
                                setState(() {
                                  _lockConfirmPasswordField = true;
                                  _obscurePasswordConfirm = !_obscurePasswordConfirm;
                                });

                                await Future.delayed(const Duration(milliseconds: 30));

                                setState(() {
                                  _lockConfirmPasswordField = false;
                                });
                              },
                              child: Icon(
                                _obscurePasswordConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              ),
                            )
                          ),
                        ),
                        if (errorCode == 500) ... [
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                            child: Text(
                              errorMessage500,
                              style: TextStyle(color: Colors.red[900], fontSize: 12),
                            ),
                          ),
                        ]
                        else if (errorCode == 422) ...[
                          if (confirmPasswordError != null)
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 4, 0, 0), // left, top, right, bottom
                              child: Text(
                                confirmPasswordError ?? '',
                                style: TextStyle(color: Colors.red[900], fontSize: 12),
                              ),
                            )
                        ],

                        SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Colors.grey;
                                }
                                return Colors.red;
                              }),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            onPressed: _isFormFilled ? _doChangePassword : null,
                            child: Text(
                              bahasa['simpan'], //']'Simpan',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            GlobalErrorBar(
              visible: showErrorBar, 
              message: errorMessage500, 
              onRetry: () {
                _doChangePassword();
              }
            ),
          ],
        ), 
      ),
    );
  }

  final Map<String, String> errorTranslationMap = {
    // current password
    'current password minimal 8 karakter':
        'Current password must be at least 8 characters',

    // new password
    'new password minimal 8 karakter':
        'New password must be at least 8 characters',

    // confirm password
    'konfirmasi password tidak cocok':
        'Password confirmation does not match',
  };

  String translateError(String message, String? langCode) {
    if (langCode == 'id') {
      return message;
    }

    final lower = message.toLowerCase().trim();

    for (final entry in errorTranslationMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return message;
  }

  void _doChangePassword() async {
    String? token = await StorageService.getToken();
    
    final body = {
        "current_password": _currentPasswordController.text.trim(),
        "password": _newPasswordController.text.trim(),
        "password_confirmation": _confirmPasswordController.text.trim(),
    };
    
    final response = await ApiService.postSetProfil('$baseapiUrl/setting/update-password',token: token, body: body, xLanguage: langCode);

    if (!mounted) return;

    if (response!['rc'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bahasa['sukses_info'])), //'Kata sandi berhasil diubah'
      );
      errorCode = 200;
      Navigator.pop(context);

    } else if (response['rc'] == 401) {
      String? errorMessageBar;
      setState(() {
        showErrorBar = true;
        errorCode = response['rc'] ?? 0;
        errorMessageBar = response['message'];
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
                      SessionManager.isGuest = false;
                      SessionManager.checkingUserModalShown = false;
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
      final data = response['data'];
      String desc = '';

      newPasswordError = null;
      confirmPasswordError = null;

      if (data is Map) {
        // final errorMessages = data.values
        //     .whereType<List>()
        //     .expand((e) => e)
        //     .whereType<String>()
        //     .toList();

        final errorMessages = data.values
          .whereType<List>()
          .expand((e) => e)
          .whereType<String>()
          .map((e) => translateError(e, langCode))
          .toList();

        desc = errorMessages.join('\n');
        if (data['password'] is List) {
          for (var msg in data['password']) {

            final translated = translateError(msg.toString(), langCode);
            final lower = translated.toLowerCase();

            if (lower.contains('new password') || lower.contains('password baru')) {
              newPasswordError = translated;
            } else if (lower.contains('confirmation') || lower.contains('konfirmasi')) {
              confirmPasswordError = translated;
            }
          }
        }
      } else {
        desc = response['message'] ?? data?.toString() ?? '';
      }

      errorCode = response['rc'] ?? 0;
      errorMessage = data;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        animType: AnimType.topSlide,
        title: bahasa['maaf'],
        desc: bahasa['error'] + '\n' + desc,
        btnOkOnPress: () {
          setState(() {});
        },
        btnOkColor: Colors.red,
        buttonsTextStyle: const TextStyle(color: Colors.white),
        headerAnimationLoop: false,
        dismissOnTouchOutside: true,
        showCloseIcon: true,
      ).show();
    }
  }

  void _unfocusAll(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}