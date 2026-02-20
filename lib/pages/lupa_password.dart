// ignore_for_file: use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';
import 'package:kreen_app_flutter/services/api_services.dart';
import 'package:kreen_app_flutter/services/lang_service.dart';
import 'package:kreen_app_flutter/services/storage_services.dart';

class LupaPasswordPage extends StatefulWidget {
  const LupaPasswordPage({super.key,});

  @override
  State<LupaPasswordPage> createState() => _LupaPasswordPageState();
}

class _LupaPasswordPageState extends State<LupaPasswordPage> {
  String? langCode;
  String? lupaPassword, lupaPasswordDesc, emailHint, sendEmail, requestSend;
  Map<String, dynamic> bahasa = {};

  bool isLoading = true;
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getBahasa();
    });
  }

  Future<void> _getBahasa() async {
    final code = await StorageService.getLanguage();

    setState(() {
      langCode = code;
    });
    
    final tempbahasa = await LangService.getJsonData(langCode!, "bahasa");

    setState(() {
      lupaPassword = tempbahasa["lupa_password"];
      lupaPasswordDesc = tempbahasa["lupa_password_desc"];
      emailHint = tempbahasa["input_email"];
      sendEmail = tempbahasa["kirim_email"];
      requestSend = tempbahasa["request_kirim"];

      bahasa = tempbahasa;

      isLoading = false;
    });
  }

  bool get _isFormFilled => _emailController.text.isNotEmpty;
  
  bool _emailTouched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red,),)
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  title: Text(lupaPassword!),
                  centerTitle: false,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                body: Container(
                  height: MediaQuery.of(context).size.height,
                  color: Colors.white,
                  padding: kGlobalPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        lupaPasswordDesc!,
                      ),

                      const SizedBox(height: 16),
                      Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text(
                          "Email",
                        ),
                      ),
                      TextField(
                        controller: _emailController,
                        autofocus: false,
                        onChanged: (value) {
                          if (!_emailTouched) {
                            setState(() => _emailTouched = true);
                          } else {
                            setState(() {});
                          }
                        },
                        decoration: InputDecoration(
                          hintText: emailHint!,
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          errorText: _emailTouched && !isValidEmail(_emailController.text)
                            ? bahasa['error_email_1']
                            : null,
                        ),
                      ),

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
                          onPressed: _isFormFilled ? _doResetPassword : null,
                          child: Text(
                            sendEmail!,
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ),
    );
  }

  void _doResetPassword () async {
    final body = {
      "email": _emailController.text
    };

    final result = await ApiService.post('/forgot-password', body: body, xLanguage: langCode);
    if(result?['rc'] != 200) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        animType: AnimType.topSlide,
        title: bahasa['maaf'],
        desc: bahasa['error'], //"Terjadi kesalahan. Silakan coba lagi.",
        btnOkOnPress: () {},
        btnOkColor: Colors.red,
        buttonsTextStyle: TextStyle(color: Colors.white),
        headerAnimationLoop: false,
        dismissOnTouchOutside: true,
        showCloseIcon: true,
      ).show().then((_) {
        Navigator.pop(context);
      });
    }
  }
}