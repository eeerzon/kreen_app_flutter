// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:kreen_app_flutter/helper/global_error_bar.dart';
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

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Stack(
          children: [
            isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.red,),)
              : SingleChildScrollView(
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

                                await Future.delayed(const Duration(milliseconds: 50));

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
                          SizedBox(height: 4,),
                          Text(
                            errorMessage500,
                            style: TextStyle(color: Colors.red),
                          ),
                        ]
                        else if (errorCode == 422) ... [
                          const SizedBox(height: 4),
                          if (errorMessage['current_password'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var err in errorMessage['current_password'])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      err,
                                      style: const TextStyle(color: Colors.red),
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

                                await Future.delayed(const Duration(milliseconds: 50));

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
                          SizedBox(height: 4,),
                          Text(
                            errorMessage500,
                            style: TextStyle(color: Colors.red),
                          ),
                        ]
                        else if (errorCode == 422) ... [
                          const SizedBox(height: 4),
                          if (errorMessage['password'] != null && (errorMessage['password'] as List).any((e) => e.toString().contains('New')))
                            Text(
                              newPasswordError!,
                              style: const TextStyle(color: Colors.red),
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

                                await Future.delayed(const Duration(milliseconds: 50));

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
                          SizedBox(height: 4,),
                          Text(
                            errorMessage500,
                            style: TextStyle(color: Colors.red),
                          ),
                        ]
                        else if (errorCode == 422) ... [
                          const SizedBox(height: 4),
                          if (errorMessage['password'] != null && (errorMessage['password'] as List).any((e) => e.toString().contains('Konfirmasi')))
                            Text(
                              confirmPasswordError!,
                              style: const TextStyle(color: Colors.red),
                            ),
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
                                  borderRadius: BorderRadius.circular(12),
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
    } else {
      final data = response['data'];
      String desc = '';

      newPasswordError = null;
      confirmPasswordError = null;

      if (data is Map) {
        final errorMessages = data.values
            .whereType<List>()
            .expand((e) => e)
            .whereType<String>()
            .toList();

        desc = errorMessages.join('\n');
        if (data['password'] is List) {
          for (var msg in data['password']) {
            final message = msg.toString();

            if (message.toLowerCase().contains('new password')) {
              newPasswordError = message;
            } else if (message.toLowerCase().contains('konfirmasi') ||
                      message.toLowerCase().contains('confirm')) {
              confirmPasswordError = message;
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