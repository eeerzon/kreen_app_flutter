// ignore_for_file: use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/constants.dart';
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
  Map<String, dynamic> eventLang = {};

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

    final tempLupaPassword = await LangService.getText(langCode!, "lupa_password");
    final tempLupaPasswordDesc = await LangService.getText(langCode!, "lupa_password_desc");
    final tempemailHint = await LangService.getText(langCode!, "input_email");
    final tempsendEmail = await LangService.getText(langCode!, "kirim_email");
    final temprequestSend = await LangService.getText(langCode!, "request_kirim");
    final tempeventLang = await LangService.getJsonData(langCode!, "event");

    setState(() {
      lupaPassword = tempLupaPassword;
      lupaPasswordDesc = tempLupaPasswordDesc;
      emailHint = tempemailHint;
      sendEmail = tempsendEmail;
      requestSend = temprequestSend;

      eventLang = tempeventLang;

      isLoading = false;
    });
  }

  bool get _isFormFilled => _emailController.text.isNotEmpty;

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red,),)
          : Scaffold(
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
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: emailHint!,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        errorText: !isValidEmail(_emailController.text)
                            ? eventLang['error_email_1']
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
    );
  }

  void _doResetPassword () async {
    final body = {
      "email": _emailController.text
    };

    final result = await ApiService.post('/forgot-password', body: body);
    if(result?['rc'] == 200) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: langCode == 'id' ? 'Berhasil' : 'Success',
        desc: requestSend!,
        transitionAnimationDuration: const Duration(milliseconds: 400),
        autoHide: const Duration(seconds: 1),
      ).show().then((_) {
        Navigator.pop(context);
      });
    }
  }
}