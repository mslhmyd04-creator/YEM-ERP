import 'package:flutter/material.dart';

class YemErpApp extends StatelessWidget {
  const YemErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YEM ERP',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(colorSchemeSeed: const Color(0xFF174B74), useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF174B74),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: _AppBar(),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'YEM ERP — المرحلة 0\nيجري إعداد التخزين المحلي الآمن قبل إدخال البيانات.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('YEM ERP'));
}
