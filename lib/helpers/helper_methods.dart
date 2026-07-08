// ignore_for_file: use_build_context_synchronously, unused_local_variable, avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/custom_exit_dialog.dart';
import 'package:bea_window_app/helpers/di.dart';
import 'package:bea_window_app/constants/app_constants.dart';

//final appData = locator.get<GetStorage>();
// final plcaeMarkAddress = locator.get<PlcaeMarkAddress>();
//declared for cart scrren calling bottom shit with this from reorder rx
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
final GlobalKey<PopupMenuButtonState<String>> popUpGlobalkey =
    GlobalKey<PopupMenuButtonState<String>>();

// Future<String?> networkImageToBase64(String imageUrl) async {
//   http.Response response = await http.get(Uri.parse(imageUrl));
//   final bytes = response.bodyBytes;

//   // ignore: unnecessary_null_comparison
//   return (bytes != null ? base64Encode(bytes) : null);
// }

Future<void> setInitValue() async {
  appData.writeIfNull(kKeyfirstTime, true);
  await appData.writeIfNull(kKeyIsLoggedIn, false);
  await appData.writeIfNull(kKeyIsExploring, false);

  await Future.delayed(const Duration(seconds: 2));
}


Future<File> getLocalFile(String filename) async {
  File f = File(filename);
  return f;
}

void showMaterialDialog(
  BuildContext context,
) {
  CustomExitDialog.show(context);
}

void rotation() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(80, 0, 0, 0),
    statusBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

Widget customeButton({
  required String name,
  required VoidCallback onCallBack,
  required double height,
  required double minWidth,
  required double borderRadius,
  required Color color,
  required TextStyle textStyle,
  required BuildContext context,
  Color? borderColor,
}) {
  return MaterialButton(
    onPressed: onCallBack,
    height: height,
    minWidth: minWidth,
    shape: RoundedRectangleBorder(
      side: BorderSide(
          color: borderColor ?? AppColors.allPrimaryColor, width: 1.5.sp),
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    color: color,
    //splashColor: Colors.white.withOpacity(0.4),
    child: Text(
      name,
      style: textStyle,
    ),
  );
}
