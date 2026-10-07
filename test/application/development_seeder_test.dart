import 'package:cafe_pos/app/dependencies.dart';
import 'package:cafe_pos/application/services/cafe_calendar.dart';
import 'package:cafe_pos/application/services/transaction_runner.dart';
import 'package:cafe_pos/application/use_cases/catalog_use_cases.dart';
import 'package:cafe_pos/application/use_cases/order_use_cases.dart';
import 'package:cafe_pos/application/use_cases/payment_use_cases.dart';
import 'package:cafe_pos/application/use_cases/report_use_cases.dart';
import 'package:cafe_pos/application/use_cases/sales_use_cases.dart';
import 'package:cafe_pos/application/use_cases/table_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../tool/development_seeder.dart';
import '../support/fakes.dart';

void main() {
  test('creates the dummy catalog and tables only once', () async {
    final _Fixture fixture = _Fixture();
    final DevelopmentSeeder seeder = DevelopmentSeeder(
      catalog: fixture.dependencies.catalog,
      tables: fixture.dependencies.tables,
    );

    final SeedSummary first = await seeder.seed();
    final SeedSummary second = await seeder.seed();

    expect(first.tablesCreated, DevelopmentSeeder.tableNames.length);
    expect(first.categoriesCreated, DevelopmentSeeder.categories.length);
    expect(first.productsCreated, 12);
    expect(first.totalCreated, 24);
    expect(second.totalCreated, 0);
    expect(fixture.tables.values, hasLength(8));
    expect(fixture.categories.values, hasLength(4));
    expect(fixture.products.values, hasLength(12));
  });

  test('preserves existing matching data instead of overwriting it', () async {
    final _Fixture fixture = _Fixture();
    final category = await fixture.dependencies.catalog.createCategory('café');
    final product = await fixture.dependencies.catalog.createProduct(
      categoryId: category.id,
      name: 'ESPRESSO',
      price: '9.99',
    );
    await fixture.dependencies.tables.createTable('mesa 1');

    final SeedSummary result = await DevelopmentSeeder(
      catalog: fixture.dependencies.catalog,
      tables: fixture.dependencies.tables,
    ).seed();

    expect(result.tablesCreated, 7);
    expect(result.categoriesCreated, 3);
    expect(result.productsCreated, 11);
    expect((await fixture.products.findById(product.id))!.priceCents, 999);
  });
}

class _Fixture {
  _Fixture() {
    final TransactionRepositories repositories = TransactionRepositories(
      categories: categories,
      products: products,
      tables: tables,
      orders: orders,
      payments: payments,
      settings: settings,
    );
    final DirectTransactionRunner transactions = DirectTransactionRunner(
      repositories,
    );
    dependencies = AppDependencies(
      catalog: CatalogUseCases(
        categories: categories,
        products: products,
        ids: ids,
        clock: () => now,
      ),
      tables: TableUseCases(tables: tables, ids: ids, clock: () => now),
      orders: OrderUseCases(
        tables: tables,
        orders: orders,
        categories: categories,
        products: products,
        transactions: transactions,
        ids: ids,
        clock: () => now,
      ),
      payments: PaymentUseCases(
        orders: orders,
        transactions: transactions,
        ids: ids,
        clock: () => now,
      ),
      sales: SalesUseCases(sales: sales, calendar: CafeCalendar(tz.UTC)),
      reports: ReportUseCases(
        reports: reports,
        calendar: CafeCalendar(tz.UTC),
        clock: () => now,
      ),
    );
  }

  final DateTime now = DateTime.utc(2026, 10, 5, 20);
  final FixedIds ids = FixedIds();
  final FakeCategoryRepository categories = FakeCategoryRepository();
  final FakeProductRepository products = FakeProductRepository();
  final FakeTableRepository tables = FakeTableRepository();
  final FakeOrderRepository orders = FakeOrderRepository();
  final FakePaymentRepository payments = FakePaymentRepository();
  final FakeSalesRepository sales = FakeSalesRepository();
  final FakeReportRepository reports = FakeReportRepository();
  final FakeSettingsRepository settings = FakeSettingsRepository();
  late final AppDependencies dependencies;
}
