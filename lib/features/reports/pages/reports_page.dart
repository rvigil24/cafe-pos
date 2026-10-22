import 'package:flutter/material.dart';

import '../../../application/services/cafe_calendar.dart';
import '../../../domain/entities/sales_report.dart';
import '../../../shared/dates/cafe_dates.dart';
import '../../../shared/money/money_parser.dart';
import '../../../shared/payments/payment_format.dart';
import '../../../shared/presentation/cafe_colors.dart';
import '../../../shared/presentation/pos_page.dart';
import '../controllers/reports_controller.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({required this.controller, super.key});

  final ReportsController controller;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _periodMenuGeneration = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return PosPage(
          title: 'Reportes',
          subtitle: 'Indicadores de ventas y desempeño del café',
          isWorking: widget.controller.status == ReportsStatus.loading,
          actions: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Actualizar reporte',
              onPressed: widget.controller.status == ReportsStatus.loading
                  ? null
                  : widget.controller.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _periodSelector(),
              Expanded(child: _body()),
            ],
          ),
        );
      },
    );
  }

  Widget _periodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: PosSurface(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<ReportPeriod>(
                key: ValueKey<(ReportPeriod, int)>((
                  widget.controller.period,
                  _periodMenuGeneration,
                )),
                initialValue: widget.controller.period,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Período'),
                items: ReportPeriod.values
                    .map(
                      (ReportPeriod value) => DropdownMenuItem<ReportPeriod>(
                        value: value,
                        child: Text(_periodLabel(value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: widget.controller.status == ReportsStatus.loading
                    ? null
                    : (ReportPeriod? value) {
                        if (value != null) {
                          _selectPeriod(value);
                        }
                      },
              ),
            ),
            if (widget.controller.period == ReportPeriod.custom &&
                widget.controller.customStart != null &&
                widget.controller.customEnd != null)
              Text(
                '${formatCafeDate(widget.controller.customStart!)} – '
                '${formatCafeDate(widget.controller.customEnd!)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    return switch (widget.controller.status) {
      ReportsStatus.loading => const Center(child: Text('Calculando reporte…')),
      ReportsStatus.error => Center(
        child: FilledButton.icon(
          onPressed: widget.controller.period == ReportPeriod.custom
              ? () => _selectPeriod(ReportPeriod.custom)
              : widget.controller.load,
          icon: const Icon(Icons.refresh),
          label: Text(widget.controller.errorMessage!),
        ),
      ),
      ReportsStatus.ready => _report(widget.controller.report!),
    };
  }

  Widget _report(SalesReport report) {
    if (report.paidOrderCount == 0) {
      return const Center(
        child: Text('No hay ventas pagadas en este período.'),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = (constraints.maxWidth - 36) / 4;
              return Row(
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: _metric(
                      'Ventas netas',
                      formatPriceCents(report.netSalesCents),
                      Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: width,
                    child: _metric(
                      'Órdenes pagadas',
                      '${report.paidOrderCount}',
                      Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: width,
                    child: _metric(
                      'Ticket promedio',
                      formatPriceCents(report.averageTicketCents),
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: width,
                    child: _metric(
                      'Unidades vendidas',
                      '${report.unitsSold}',
                      Icons.local_cafe_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: _barSection(
                      'Productos más vendidos',
                      report.bestSellingProducts
                          .map(
                            (ProductUnits value) => (
                              label: value.name,
                              amount: value.units,
                              value: '${value.units} unidades',
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _barSection(
                      'Ventas por categoría',
                      report.salesByCategory
                          .map(
                            (NamedSalesTotal value) => (
                              label: value.name,
                              amount: value.totalCents,
                              value: formatPriceCents(value.totalCents),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _barSection(
                      'Ventas por hora',
                      report.salesByHour
                          .map(
                            (HourlySalesTotal value) => (
                              label:
                                  '${value.hour.toString().padLeft(2, '0')}:00',
                              amount: value.totalCents,
                              value: formatPriceCents(value.totalCents),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _barSection(
                      'Totales por método',
                      report.totalsByPaymentMethod
                          .map(
                            (PaymentMethodTotal value) => (
                              label: paymentMethodLabel(value.method),
                              amount: value.totalCents,
                              value: formatPriceCents(value.totalCents),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Semantics(
      label: '$label: $value',
      child: PosSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: CafeColors.terracotta),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: CafeColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barSection(
    String title,
    List<({int amount, String label, String value})> rows,
  ) {
    final int maximum = rows.fold<int>(
      0,
      (int current, row) => row.amount > current ? row.amount : current,
    );
    return PosSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final row in rows) ...<Widget>[
            Semantics(
              label: '${row.label}: ${row.value}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          row.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: ColoredBox(
                      color: CafeColors.terracottaSoft,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: maximum == 0 ? 0 : row.amount / maximum,
                          child: const ColoredBox(
                            color: CafeColors.terracotta,
                            child: SizedBox(height: 8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _selectPeriod(ReportPeriod period) async {
    if (period != ReportPeriod.custom) {
      await widget.controller.load(period: period);
      return;
    }
    final DateTime now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange:
          widget.controller.customStart != null &&
              widget.controller.customEnd != null
          ? DateTimeRange(
              start: widget.controller.customStart!,
              end: widget.controller.customEnd!,
            )
          : null,
      helpText: 'Seleccionar período del reporte',
    );
    if (range != null) {
      await widget.controller.load(
        period: ReportPeriod.custom,
        customStart: range.start,
        customEnd: range.end,
      );
    } else if (mounted) {
      setState(() => _periodMenuGeneration += 1);
    }
  }

  String _periodLabel(ReportPeriod period) {
    return switch (period) {
      ReportPeriod.today => 'Hoy',
      ReportPeriod.yesterday => 'Ayer',
      ReportPeriod.thisWeek => 'Esta semana',
      ReportPeriod.thisMonth => 'Este mes',
      ReportPeriod.custom => 'Personalizado',
    };
  }
}
