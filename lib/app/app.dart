import 'package:flutter/material.dart';

import '../application/use_cases/catalog_use_cases.dart';
import '../features/products/controllers/catalog_controller.dart';
import '../features/products/pages/catalog_page.dart';
import 'theme.dart';

typedef CatalogLoader = Future<CatalogUseCases> Function();

class CafePosApp extends StatelessWidget {
  const CafePosApp({this.catalogUseCases, this.catalogLoader, super.key})
    : assert(catalogUseCases == null || catalogLoader == null);

  final CatalogUseCases? catalogUseCases;
  final CatalogLoader? catalogLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cafe POS',
      theme: buildCafeTheme(),
      home: catalogUseCases != null
          ? CatalogPage(controller: CatalogController(catalogUseCases!))
          : catalogLoader != null
          ? _CatalogBootstrap(loader: catalogLoader!)
          : const _BootstrapPage(),
    );
  }
}

class _CatalogBootstrap extends StatefulWidget {
  const _CatalogBootstrap({required this.loader});

  final CatalogLoader loader;

  @override
  State<_CatalogBootstrap> createState() => _CatalogBootstrapState();
}

class _CatalogBootstrapState extends State<_CatalogBootstrap> {
  late Future<CatalogUseCases> _future = widget.loader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CatalogUseCases>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<CatalogUseCases> snapshot) {
        if (snapshot.hasData) {
          return CatalogPage(
            controller: CatalogController(snapshot.requireData),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.storage_outlined, size: 56),
                  const SizedBox(height: 12),
                  const Text('No se pudo abrir la información local.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _future = widget.loader());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
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
