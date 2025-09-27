import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vos_app/app.dart';
import 'package:vos_app/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependency injection
  await configureDependencies();

  runApp(const VosApp());
}

class VosApp extends StatelessWidget {
  const VosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return const App();
      },
    );
  }
}