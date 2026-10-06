import 'package:cafe_pos/app/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'development_seeder.dart';

const String _successMarker = 'CAFE_POS_SEED_SUCCESS';
const String _failureMarker = 'CAFE_POS_SEED_FAILURE';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const _SeedApp());
}

class _SeedApp extends StatefulWidget {
  const _SeedApp();

  @override
  State<_SeedApp> createState() => _SeedAppState();
}

class _SeedAppState extends State<_SeedApp> {
  late final Future<SeedSummary> _seed = _runSeeder();

  Future<SeedSummary> _runSeeder() async {
    try {
      final AppDependencies dependencies = await buildAppDependencies();
      final SeedSummary summary = await DevelopmentSeeder(
        catalog: dependencies.catalog,
        tables: dependencies.tables,
      ).seed();
      debugPrint('$_successMarker $summary');
      return summary;
    } on Object catch (error, stackTrace) {
      debugPrint('$_failureMarker $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: FutureBuilder<SeedSummary>(
            future: _seed,
            builder:
                (BuildContext context, AsyncSnapshot<SeedSummary> snapshot) {
                  if (snapshot.hasError) {
                    return const Text('No se pudieron crear los datos dummy.');
                  }
                  if (!snapshot.hasData) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Creando datos dummy…'),
                      ],
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.check_circle_outline, size: 64),
                      const SizedBox(height: 16),
                      const Text('Datos dummy listos'),
                      const SizedBox(height: 8),
                      Text(snapshot.requireData.toString()),
                    ],
                  );
                },
          ),
        ),
      ),
    );
  }
}
