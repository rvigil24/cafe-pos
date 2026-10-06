import 'package:cafe_pos/application/services/transaction_runner.dart';
import 'package:cafe_pos/application/use_cases/order_use_cases.dart';
import 'package:cafe_pos/application/use_cases/table_use_cases.dart';
import 'package:cafe_pos/domain/entities/cafe_table.dart';
import 'package:cafe_pos/domain/entities/category.dart';
import 'package:cafe_pos/domain/entities/order.dart';
import 'package:cafe_pos/domain/entities/product.dart';
import 'package:cafe_pos/domain/errors/domain_error.dart';
import 'package:cafe_pos/features/home/controllers/home_controller.dart';
import 'package:cafe_pos/features/home/pages/home_page.dart';
import 'package:cafe_pos/features/orders/controllers/order_controller.dart';
import 'package:cafe_pos/features/orders/pages/order_page.dart';
import 'package:cafe_pos/features/tables/controllers/table_controller.dart';
import 'package:cafe_pos/features/tables/pages/table_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../support/fakes.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  testWidgets('Home distinguishes free tables and opens a created order', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _Fixture();
    String? openedOrderId;
    await _pumpLandscape(
      tester,
      HomePage(
        controller: HomeController(fixture.useCases),
        onOpenOrder: (String id) => openedOrderId = id,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Libre'), findsOneWidget);
    expect(find.text('No hay órdenes para llevar'), findsOneWidget);
    await tester.tap(find.text('Mesa 1'));
    await tester.pumpAndSettle();

    expect(openedOrderId, isNotNull);
    expect(fixture.orders.orders.single.tableId, fixture.table.id);
  });

  testWidgets('table settings confirms deactivation and explains rejection', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _Fixture();
    fixture.tables.updateError = const OccupiedTableError(
      'No se puede desactivar una mesa con una orden abierta.',
    );
    await _pumpLandscape(
      tester,
      TableSettingsPage(controller: TableController(fixture.tableUseCases)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Acciones de Mesa 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar'));
    await tester.pumpAndSettle();
    expect(find.text('Desactivar Mesa 1'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Desactivar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se puede desactivar una mesa con una orden abierta.'),
      findsOneWidget,
    );
  });

  testWidgets('table form stays usable with a landscape keyboard viewport', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _Fixture();
    await _pumpLandscape(
      tester,
      TableSettingsPage(controller: TableController(fixture.tableUseCases)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Crear mesa'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 430);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    expect(tester.takeException(), isNull);
    final Rect field = tester.getRect(find.byType(TextFormField));
    expect(field.height, greaterThanOrEqualTo(48));
    await tester.enterText(find.byType(TextFormField), 'Mesa 2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Mesa 2'), findsOneWidget);
  });

  testWidgets('order editor persists quantity and note changes', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _Fixture();
    final Order order = await fixture.useCases.createTakeaway();
    bool closed = false;
    final OrderController controller = OrderController(
      fixture.useCases,
      order.id,
    );
    await _pumpLandscape(
      tester,
      OrderPage(
        controller: controller,
        onClose: () => closed = true,
        onCancelled: () => closed = true,
        onProceedToPayment: () {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Café'));
    await tester.pumpAndSettle();
    expect(controller.details!.order.totalCents, 250);
    await tester.tap(find.byTooltip('Aumentar'));
    await tester.pumpAndSettle();
    expect(controller.details!.order.totalCents, 500);

    await tester.tap(find.byTooltip('Editar nota de Café'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 430);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byType(TextFormField)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.enterText(find.byType(TextFormField), 'Sin azúcar');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar nota'));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Nota: Sin azúcar'), findsOneWidget);

    fixture.products.values[0] = fixture.product.copyWith(isAvailable: false);
    await controller.load();
    await tester.pumpAndSettle();
    expect(
      find.text('No disponible; solo puedes disminuir o eliminar.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Producto no disponible'), findsOneWidget);
    expect(closed, isFalse);
  });

  testWidgets('order cancellation validates a reason and confirms once', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = _Fixture();
    final Order order = await fixture.useCases.createDineIn(fixture.table.id);
    bool cancelled = false;
    await _pumpLandscape(
      tester,
      OrderPage(
        controller: OrderController(fixture.useCases, order.id),
        onClose: () {},
        onCancelled: () => cancelled = true,
        onProceedToPayment: () {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cancelar orden'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar orden'));
    await tester.pump();
    expect(find.text('Ingresa el motivo de cancelación.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Error de captura');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar orden'));
    await tester.pumpAndSettle();

    expect(cancelled, isTrue);
    expect(fixture.orders.orders.single.status, OrderStatus.cancelled);
  });
}

Future<void> _pumpLandscape(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: child));
}

class _Fixture {
  _Fixture() {
    tables.values.add(table);
    categories.values.add(category);
    products.values.add(product);
    final TransactionRepositories repositories = TransactionRepositories(
      categories: categories,
      products: products,
      tables: tables,
      orders: orders,
      payments: payments,
      settings: settings,
    );
    useCases = OrderUseCases(
      tables: tables,
      orders: orders,
      categories: categories,
      products: products,
      transactions: DirectTransactionRunner(repositories),
      ids: FixedIds(),
      clock: () => now,
    );
    tableUseCases = TableUseCases(
      tables: tables,
      ids: FixedIds(),
      clock: () => now,
    );
  }

  final DateTime now = DateTime.utc(2026, 10, 3, 18);
  final FakeCategoryRepository categories = FakeCategoryRepository();
  final FakeProductRepository products = FakeProductRepository();
  final FakeTableRepository tables = FakeTableRepository();
  final FakeOrderRepository orders = FakeOrderRepository();
  final FakePaymentRepository payments = FakePaymentRepository();
  final FakeSettingsRepository settings = FakeSettingsRepository();
  late final OrderUseCases useCases;
  late final TableUseCases tableUseCases;

  late final CafeTable table = CafeTable(
    id: 'table-1',
    name: 'Mesa 1',
    sortOrder: 0,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  late final Category category = Category(
    id: 'category-1',
    name: 'Bebidas',
    sortOrder: 0,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  late final Product product = Product(
    id: 'product-1',
    categoryId: category.id,
    name: 'Café',
    priceCents: 250,
    isAvailable: true,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
