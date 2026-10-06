import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../application/use_cases/payment_use_cases.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_details.dart';
import '../../../domain/entities/payment.dart';
import '../../../shared/money/money_parser.dart';
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
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Volver a la orden',
              onPressed: widget.controller.isSubmitting ? null : widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Cobrar orden'),
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Orden #${order.orderNumber}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                formatPriceCents(order.totalCents),
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
                semanticsLabel: 'Total ${formatPriceCents(order.totalCents)}',
              ),
              const SizedBox(height: 24),
              SegmentedButton<PaymentMethod>(
                segments: const <ButtonSegment<PaymentMethod>>[
                  ButtonSegment<PaymentMethod>(
                    value: PaymentMethod.cash,
                    icon: Icon(Icons.payments_outlined),
                    label: Text('Efectivo'),
                  ),
                  ButtonSegment<PaymentMethod>(
                    value: PaymentMethod.transfer,
                    icon: Icon(Icons.account_balance_outlined),
                    label: Text('Transferencia'),
                  ),
                  ButtonSegment<PaymentMethod>(
                    value: PaymentMethod.creditCard,
                    icon: Icon(Icons.credit_card),
                    label: Text('Tarjeta de crédito'),
                  ),
                ],
                selected: <PaymentMethod>{widget.controller.method},
                onSelectionChanged: widget.controller.isSubmitting
                    ? null
                    : (Set<PaymentMethod> selection) {
                        widget.controller.selectMethod(selection.single);
                      },
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.controller.isSubmitting ? null : _submit,
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
              ),
            ],
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
