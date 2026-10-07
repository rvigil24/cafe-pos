import 'package:flutter/material.dart';

import '../../../application/services/cafe_calendar.dart';
import '../../../domain/entities/sales_report.dart';
import '../../../shared/dates/cafe_dates.dart';
import '../../../shared/money/money_parser.dart';
import '../../../shared/payments/payment_format.dart';
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
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reportes'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Actualizar reporte',
                onPressed: widget.controller.status == ReportsStatus.loading
                    ? null
                    : widget.controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _periodSelector(),
              if (widget.controller.status == ReportsStatus.loading)
                const LinearProgressIndicator(),
              Expanded(child: _body()),
            ],
          ),
        );
      },
    );
  }

  Widget _periodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _metric('Ventas netas', formatPriceCents(report.netSalesCents)),
              _metric('Órdenes pagadas', '${report.paidOrderCount}'),
              _metric(
                'Ticket promedio',
                formatPriceCents(report.averageTicketCents),
              ),
              _metric('Unidades vendidas', '${report.unitsSold}'),
            ],
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
                    child: _section(
                      'Productos más vendidos',
                      report.bestSellingProducts.map(
                        (ProductUnits value) =>
                            _valueRow(value.name, '${value.units} unidades'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _section(
                      'Ventas por categoría',
                      report.salesByCategory.map(
                        (NamedSalesTotal value) => _valueRow(
                          value.name,
                          formatPriceCents(value.totalCents),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _section(
                      'Ventas por hora',
                      report.salesByHour.map(
                        (HourlySalesTotal value) => _valueRow(
                          '${value.hour.toString().padLeft(2, '0')}:00',
                          formatPriceCents(value.totalCents),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _section(
                      'Totales por método',
                      report.totalsByPaymentMethod.map(
                        (PaymentMethodTotal value) => _valueRow(
                          paymentMethodLabel(value.method),
                          formatPriceCents(value.totalCents),
                        ),
                      ),
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

  Widget _metric(String label, String value) {
    return Semantics(
      label: '$label: $value',
      child: SizedBox(
        width: 190,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Iterable<Widget> rows) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _valueRow(String label, String value) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
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
