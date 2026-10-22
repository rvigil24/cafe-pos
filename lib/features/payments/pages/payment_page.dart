import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../application/use_cases/payment_use_cases.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_details.dart';
import '../../../domain/entities/payment.dart';
import '../../../shared/money/money_parser.dart';
import '../../../shared/presentation/cafe_colors.dart';
import '../../../shared/presentation/pos_page.dart';
import '../controllers/payment_controller.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    required this.controller,
    required this.onBack,
    required this.onPaid,
    super.key,
  });

  final PaymentController controller;
  final VoidCallback onBack;
  final ValueChanged<PaymentResult> onPaid;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _received = TextEditingController();
  final TextEditingController _reference = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
    _received.addListener(_refreshChange);
  }

  @override
  void dispose() {
    _received
      ..removeListener(_refreshChange)
      ..dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return PosPage(
          title: 'Cobrar orden',
          subtitle: 'Revisa el total, registra el método y confirma el pago',
          isWorking: widget.controller.isSubmitting,
          leading: IconButton.filledTonal(
            tooltip: 'Volver a la orden',
            onPressed: widget.controller.isSubmitting ? null : widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          body: _body(),
        );
      },
    );
  }

  Widget _body() {
    return switch (widget.controller.status) {
      PaymentStatus.loading => const Center(child: CircularProgressIndicator()),
      PaymentStatus.error => Center(
        child: FilledButton.icon(
          onPressed: widget.controller.load,
          icon: const Icon(Icons.refresh),
          label: Text(widget.controller.errorMessage!),
        ),
      ),
      PaymentStatus.ready => _form(widget.controller.details!),
    };
  }

  Widget _form(OrderDetails details) {
    final Order order = details.order;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: PosSurface(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Orden #${order.orderNumber}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          order.type == OrderType.takeaway
                              ? 'Para llevar'
                              : order.tableNameSnapshot!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: CafeColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: details.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (BuildContext context, int index) {
                        final item = details.items[index];
                        return Row(
                          children: <Widget>[
                            Text(
                              '${item.quantity}×',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item.productNameSnapshot)),
                            Text(formatPriceCents(item.totalCents)),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    color: CafeColors.cream,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Total a cobrar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatPriceCents(order.totalCents),
                              style: Theme.of(context).textTheme.displayMedium,
                              semanticsLabel:
                                  'Total ${formatPriceCents(order.totalCents)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: PosSurface(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Semantics(
                            label: 'Método de pago',
                            child: _methodSelector(),
                          ),
                          const SizedBox(height: 12),
                          if (widget.controller.method == PaymentMethod.cash)
                            _cashFields()
                          else
                            _manualFields(),
                          if (widget.controller.errorMessage
                              case final String message) ...<Widget>[
                            const SizedBox(height: 16),
                            MaterialBanner(
                              content: Text(message),
                              leading: const Icon(Icons.error_outline),
                              actions: const <Widget>[SizedBox.shrink()],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  PosActionBar(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: widget.controller.isSubmitting
                          ? null
                          : _submit,
                      icon: widget.controller.isSubmitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        widget.controller.isSubmitting
                            ? 'Procesando…'
                            : 'Confirmar pago',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: CafeColors.terracotta,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodSelector() {
    return Row(
      children: <Widget>[
        Expanded(child: _methodButton(PaymentMethod.cash, 'Efectivo')),
        const SizedBox(width: 8),
        Expanded(child: _methodButton(PaymentMethod.transfer, 'Transferencia')),
        const SizedBox(width: 8),
        Expanded(
          child: _methodButton(PaymentMethod.creditCard, 'Tarjeta de crédito'),
        ),
      ],
    );
  }

  Widget _methodButton(PaymentMethod method, String label) {
    return Semantics(
      selected: widget.controller.method == method,
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: widget.controller.isSubmitting
              ? null
              : () => widget.controller.selectMethod(method),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            backgroundColor: widget.controller.method == method
                ? CafeColors.terracottaSoft
                : Colors.white,
            foregroundColor: CafeColors.espresso,
            side: BorderSide(
              color: widget.controller.method == method
                  ? CafeColors.terracotta
                  : CafeColors.outline,
            ),
          ),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _cashFields() {
    final int? change = widget.controller.changeFor(_received.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _received,
          enabled: !widget.controller.isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Monto recibido',
            prefixText: r'$ ',
            errorText: widget.controller.receivedError,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          change == null || change < 0
              ? 'Cambio: —'
              : 'Cambio: ${formatPriceCents(change)}',
          style: Theme.of(context).textTheme.headlineSmall,
          semanticsLabel: change == null || change < 0
              ? 'Cambio no disponible'
              : 'Cambio ${formatPriceCents(change)}',
        ),
      ],
    );
  }

  Widget _manualFields() {
    final bool card = widget.controller.method == PaymentMethod.creditCard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!card)
          TextField(
            controller: _reference,
            enabled: !widget.controller.isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Referencia o comprobante (opcional)',
            ),
          ),
        if (card) ...<Widget>[
          const Text(
            'No ingreses número de tarjeta, vencimiento ni código de seguridad.',
          ),
        ],
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: widget.controller.manualConfirmed,
          onChanged: widget.controller.isSubmitting
              ? null
              : (bool? value) {
                  widget.controller.setManualConfirmed(value ?? false);
                },
          title: Text(
            card
                ? 'Confirmo que el cobro con tarjeta fue verificado.'
                : 'Confirmo que la transferencia fue verificada.',
          ),
          subtitle: widget.controller.confirmationError == null
              ? null
              : Text(
                  widget.controller.confirmationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  void _refreshChange() => setState(() {});

  Future<void> _submit() async {
    final PaymentResult? result = await widget.controller.submit(
      rawReceived: _received.text,
      reference: _reference.text,
    );
    if (result != null && mounted) {
      widget.onPaid(result);
    }
  }
}
