import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class ZomiaApp extends StatelessWidget {
  const ZomiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zomia',
      theme: buildZomiaTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
