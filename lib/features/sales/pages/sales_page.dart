import 'package:flutter/material.dart';

import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sale.dart';
import '../../../shared/dates/cafe_dates.dart';
import '../../../shared/money/money_parser.dart';
import '../../../shared/payments/payment_format.dart';
import '../controllers/sales_controller.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({required this.controller, super.key});

  final SalesController controller;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  late final TextEditingController _orderNumber = TextEditingController(
    text: widget.controller.orderNumber,
  );
  DateTimeRange? _dateRange;
  PaymentMethod? _method;

  @override
  void initState() {
    super.initState();
    final DateTime? start = widget.controller.startDate;
    final DateTime? end = widget.controller.endDate;
    if (start != null && end != null) {
      _dateRange = DateTimeRange(start: start, end: end);
    }
    _method = widget.controller.paymentMethod;
    widget.controller.load();
  }

  @override
  void dispose() {
    _orderNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ventas'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Actualizar ventas',
                onPressed: widget.controller.status == SalesStatus.loading
                    ? null
                    : widget.controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _filters(),
              if (widget.controller.status == SalesStatus.loading)
                const LinearProgressIndicator(),
              Expanded(child: _body()),
            ],
          ),
        );
      },
    );
  }

  Widget _filters() {
    final DateTimeRange? range = _dateRange;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 190,
            child: TextField(
              controller: _orderNumber,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Número de orden',
                prefixIcon: Icon(Icons.search),
              ).copyWith(errorText: widget.controller.orderNumberError),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _chooseDates,
            icon: const Icon(Icons.date_range),
            label: Text(
              range == null
                  ? 'Todas las fechas'
                  : '${formatCafeDate(range.start)} – ${formatCafeDate(range.end)}',
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<PaymentMethod?>(
              key: ValueKey<PaymentMethod?>(_method),
              initialValue: _method,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Método'),
              items: <DropdownMenuItem<PaymentMethod?>>[
                const DropdownMenuItem<PaymentMethod?>(child: Text('Todos')),
                ...PaymentMethod.values.map(
                  (PaymentMethod value) => DropdownMenuItem<PaymentMethod?>(
                    value: value,
                    child: Text(paymentMethodLabel(value)),
                  ),
                ),
              ],
              onChanged: (PaymentMethod? value) {
                setState(() => _method = value);
              },
            ),
          ),
          FilledButton.icon(
            onPressed: widget.controller.status == SalesStatus.loading
                ? null
                : _applyFilters,
            icon: const Icon(Icons.filter_alt),
            label: const Text('Aplicar'),
          ),
          TextButton(
            onPressed: widget.controller.status == SalesStatus.loading
                ? null
                : _clearFilters,
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return switch (widget.controller.status) {
      SalesStatus.loading => const Center(
        child: Text('Cargando historial de ventas…'),
      ),
      SalesStatus.error => Center(
        child: FilledButton.icon(
          onPressed: widget.controller.load,
          icon: const Icon(Icons.refresh),
          label: Text(widget.controller.errorMessage!),
        ),
      ),
      SalesStatus.ready =>
        widget.controller.sales.isEmpty
            ? const Center(
                child: Text('No hay ventas que coincidan con los filtros.'),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(flex: 2, child: _salesList()),
                  const VerticalDivider(width: 1),
                  Expanded(flex: 3, child: _details()),
                ],
              ),
    };
  }

  Widget _salesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.controller.sales.length,
      itemBuilder: (BuildContext context, int index) {
        final SaleSummary sale = widget.controller.sales[index];
        final bool selected =
            widget.controller.selected?.sale.orderId == sale.orderId;
        return Card(
          child: Semantics(
            button: true,
            label:
                'Orden ${sale.orderNumber}, ${formatCafeDateTime(sale.paidAt)}, '
                '${formatPriceCents(sale.totalCents)}, '
                '${paymentMethodLabel(sale.paymentMethod)}',
            child: ListTile(
              selected: selected,
              onTap: () => widget.controller.selectSale(sale.orderId),
              title: Text('Orden #${sale.orderNumber}'),
              subtitle: Text(
                '${formatCafeDateTime(sale.paidAt)}\n'
                '${_orderLocation(sale)} · ${paymentMethodLabel(sale.paymentMethod)}',
              ),
              isThreeLine: true,
              trailing: Text(
                formatPriceCents(sale.totalCents),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _details() {
    return switch (widget.controller.detailsStatus) {
      SaleDetailsStatus.idle => const Center(
        child: Text('Selecciona una venta para ver su detalle.'),
      ),
      SaleDetailsStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      SaleDetailsStatus.error => Center(
        child: Text(widget.controller.detailsErrorMessage!),
      ),
      SaleDetailsStatus.ready => _detailsContent(widget.controller.selected!),
    };
  }

  Widget _detailsContent(SaleDetails details) {
    final Payment payment = details.payment;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(
          'Orden #${details.sale.orderNumber}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${formatCafeDateTime(details.sale.paidAt)} · ${_orderLocation(details.sale)}',
        ),
        const SizedBox(height: 20),
        Text('Productos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...details.items.map(_itemTile),
        const Divider(height: 32),
        _detailRow('Total', formatPriceCents(details.sale.totalCents)),
        _detailRow('Método', paymentMethodLabel(payment.method)),
        if (payment.receivedCents != null) ...<Widget>[
          _detailRow('Recibido', formatPriceCents(payment.receivedCents!)),
          _detailRow('Cambio', formatPriceCents(payment.changeCents!)),
        ],
        if (payment.reference != null)
          _detailRow('Referencia', payment.reference!),
      ],
    );
  }

  Widget _itemTile(OrderItem item) {
    return Card.outlined(
      child: ListTile(
        title: Text('${item.quantity} × ${item.productNameSnapshot}'),
        subtitle: Text(
          '${item.categoryNameSnapshot} · ${formatPriceCents(item.unitPriceCents)} c/u'
          '${item.note == null ? '' : '\nNota: ${item.note}'}',
        ),
        trailing: Text(formatPriceCents(item.totalCents)),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _orderLocation(SaleSummary sale) {
    return sale.type == OrderType.takeaway
        ? 'Para llevar'
        : sale.tableNameSnapshot!;
  }

  Future<void> _chooseDates() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _dateRange,
      helpText: 'Filtrar por fecha de pago',
    );
    if (result != null && mounted) {
      setState(() => _dateRange = result);
    }
  }

  Future<void> _applyFilters() {
    return widget.controller.applyFilters(
      orderNumber: _orderNumber.text,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      paymentMethod: _method,
    );
  }

  Future<void> _clearFilters() async {
    _orderNumber.clear();
    setState(() {
      _dateRange = null;
      _method = null;
    });
    await widget.controller.clearFilters();
  }
}
