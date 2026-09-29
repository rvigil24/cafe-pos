import 'package:flutter/material.dart';

import 'theme.dart';

class CafePosApp extends StatelessWidget {
  const CafePosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cafe POS',
      theme: buildCafeTheme(),
      home: const _BootstrapPage(),
    );
  }
}

class _BootstrapPage extends StatelessWidget {
  const _BootstrapPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          container: true,
          label: 'Cafe POS is ready',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.local_cafe_outlined, size: 72),
              SizedBox(height: 16),
              Text('Cafe POS', style: TextStyle(fontSize: 32)),
              SizedBox(height: 8),
              Text('Milestone 0 ready'),
            ],
          ),
        ),
      ),
    );
  }
}
