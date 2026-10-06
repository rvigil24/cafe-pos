import 'package:flutter/material.dart';

import '../features/home/controllers/home_controller.dart';
import '../features/home/pages/home_page.dart';
import '../features/orders/controllers/order_controller.dart';
import '../features/orders/pages/order_page.dart';
import '../features/payments/controllers/payment_controller.dart';
import '../features/payments/pages/payment_page.dart';
import '../features/products/controllers/catalog_controller.dart';
import '../features/products/pages/catalog_page.dart';
import '../features/tables/controllers/table_controller.dart';
import '../features/tables/pages/table_settings_page.dart';
import 'dependencies.dart';
import 'theme.dart';

typedef DependenciesLoader = Future<AppDependencies> Function();

class CafePosApp extends StatelessWidget {
  const CafePosApp({this.dependencies, this.dependenciesLoader, super.key})
    : assert(dependencies == null || dependenciesLoader == null);

  final AppDependencies? dependencies;
  final DependenciesLoader? dependenciesLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cafe POS',
      theme: buildCafeTheme(),
      home: dependencies != null
          ? CafeShell(dependencies: dependencies!)
          : dependenciesLoader != null
          ? _DependenciesBootstrap(loader: dependenciesLoader!)
          : const _BootstrapPage(),
    );
  }
}

class _DependenciesBootstrap extends StatefulWidget {
  const _DependenciesBootstrap({required this.loader});

  final DependenciesLoader loader;

  @override
  State<_DependenciesBootstrap> createState() => _DependenciesBootstrapState();
}

class _DependenciesBootstrapState extends State<_DependenciesBootstrap> {
  late Future<AppDependencies> _future = widget.loader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<AppDependencies> snapshot) {
        if (snapshot.hasData) {
          return CafeShell(dependencies: snapshot.requireData);
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

class CafeShell extends StatefulWidget {
  const CafeShell({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<CafeShell> createState() => _CafeShellState();
}

class _CafeShellState extends State<CafeShell> {
  late final HomeController _home = HomeController(widget.dependencies.orders);
  late final CatalogController _catalog = CatalogController(
    widget.dependencies.catalog,
  );
  late final TableController _tables = TableController(
    widget.dependencies.tables,
  );
  int _section = 0;
  OrderController? _order;
  PaymentController? _payment;

  @override
  void dispose() {
    _home.dispose();
    _catalog.dispose();
    _tables.dispose();
    _order?.dispose();
    _payment?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _section,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: _selectSection,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Inicio'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_shopping_cart_outlined),
                selectedIcon: Icon(Icons.add_shopping_cart),
                label: Text('Nueva orden'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Productos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Configuración'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    final PaymentController? payment = _payment;
    if (payment != null) {
      return PaymentPage(
        key: ValueKey<String>('payment-${payment.orderId}'),
        controller: payment,
        onBack: () => _returnToOrder(payment.orderId),
        onPaid: (_) => _closeOrder(),
      );
    }
    final OrderController? order = _order;
    if (order != null) {
      return OrderPage(
        key: ValueKey<String>(order.orderId),
        controller: order,
        onClose: _closeOrder,
        onCancelled: _closeOrder,
        onProceedToPayment: () => _openPayment(order.orderId),
      );
    }
    return switch (_section) {
      0 => HomePage(controller: _home, onOpenOrder: _openOrder),
      1 => HomePage(
        controller: _home,
        onOpenOrder: _openOrder,
        creationOnly: true,
      ),
      2 => CatalogPage(controller: _catalog),
      _ => TableSettingsPage(controller: _tables),
    };
  }

  void _selectSection(int value) {
    if (_payment?.isSubmitting == true) {
      return;
    }
    _order?.dispose();
    _payment?.dispose();
    setState(() {
      _order = null;
      _payment = null;
      _section = value;
    });
  }

  void _openOrder(String id) {
    _order?.dispose();
    _payment?.dispose();
    setState(() {
      _payment = null;
      _order = OrderController(widget.dependencies.orders, id);
    });
  }

  void _openPayment(String id) {
    _order?.dispose();
    _payment?.dispose();
    setState(() {
      _order = null;
      _payment = PaymentController(widget.dependencies.payments, id);
    });
  }

  void _returnToOrder(String id) {
    _openOrder(id);
  }

  void _closeOrder() {
    _order?.dispose();
    _payment?.dispose();
    setState(() {
      _order = null;
      _payment = null;
      _section = 0;
    });
    _home.load();
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
