import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

void showLoadingDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text("Memuat data..."),
        ],
      ),
    ).show();
  }

void hideLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}
