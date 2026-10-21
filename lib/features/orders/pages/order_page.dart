import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_details.dart';
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/product.dart';
import '../../../shared/money/money_parser.dart';
import '../../../shared/presentation/cafe_colors.dart';
import '../../../shared/presentation/pos_page.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../controllers/order_controller.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({
    required this.controller,
    required this.onClose,
    required this.onCancelled,
    required this.onProceedToPayment,
    super.key,
  });

  final OrderController controller;
  final VoidCallback onClose;
  final VoidCallback onCancelled;
  final VoidCallback onProceedToPayment;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
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
          title: _title(),
          subtitle: 'Agrega productos y revisa la orden antes de cobrar',
          isWorking: widget.controller.isSaving,
          leading: IconButton.filledTonal(
            tooltip: 'Guardar y volver',
            onPressed: widget.controller.isSaving ? null : widget.onClose,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: <Widget>[
            PosStatusPill(
              label: widget.controller.isSaving ? 'Guardando…' : 'Guardado',
              icon: widget.controller.isSaving
                  ? Icons.sync
                  : Icons.cloud_done_outlined,
              foreground: CafeColors.sage,
              background: CafeColors.sageSoft,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Cancelar orden',
              onPressed: widget.controller.isSaving ? null : _cancelOrder,
              icon: const Icon(Icons.cancel_outlined),
              style: IconButton.styleFrom(
                foregroundColor: CafeColors.danger,
                backgroundColor: CafeColors.dangerSoft,
              ),
            ),
          ],
          body: _body(),
        );
      },
    );
  }

  String _title() {
    final Order? order = widget.controller.details?.order;
    if (order == null) {
      return 'Orden';
    }
    final String destination = order.type == OrderType.dineIn
        ? order.tableNameSnapshot!
        : 'Para llevar';
    return 'Orden #${order.orderNumber} · $destination';
  }

  Widget _body() {
    switch (widget.controller.status) {
      case OrderEditorStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case OrderEditorStatus.error:
        return Center(
          child: FilledButton.icon(
            onPressed: widget.controller.load,
            icon: const Icon(Icons.refresh),
            label: Text(widget.controller.errorMessage!),
          ),
        );
      case OrderEditorStatus.ready:
        return _editor(widget.controller.details!);
    }
  }

  Widget _editor(OrderDetails details) {
    return Column(
      children: <Widget>[
        if (widget.controller.errorMessage != null)
          MaterialBanner(
            content: Text(widget.controller.errorMessage!),
            leading: const Icon(Icons.error_outline),
            actions: const <Widget>[SizedBox.shrink()],
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 900;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(flex: compact ? 6 : 3, child: _catalog()),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: compact ? 5 : 2,
                      child: _orderLines(details),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _catalog() {
    if (widget.controller.categories.isEmpty) {
      return const Center(
        child: Text('No hay productos disponibles para agregar.'),
      );
    }
    return PosSurface(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 66,
              color: CafeColors.cream,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: widget.controller.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final Category category = widget.controller.categories[index];
                  return ChoiceChip(
                    label: Text(category.name),
                    selected:
                        category.id == widget.controller.selectedCategoryId,
                    onSelected: widget.controller.isSaving
                        ? null
                        : (_) => widget.controller.selectCategory(category.id),
                  );
                },
              ),
            ),
            Expanded(
              child: widget.controller.selectedProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay productos disponibles en esta categoría.',
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisExtent: 112,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: widget.controller.selectedProducts.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Product product =
                            widget.controller.selectedProducts[index];
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: CafeColors.ivory,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: CafeColors.outlineSoft),
                          ),
                          child: InkWell(
                            onTap: widget.controller.isSaving
                                ? null
                                : () =>
                                      widget.controller.addProduct(product.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatPriceCents(product.priceCents),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: CafeColors.terracotta,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderLines(OrderDetails details) {
    return PosSurface(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
              color: CafeColors.cream,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Tu orden',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${details.items.length} ${details.items.length == 1 ? 'producto' : 'productos'}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: CafeColors.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: details.items.isEmpty
                  ? LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            if (constraints.maxHeight < 150) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'Orden vacía · toca un producto',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.touch_app_outlined,
                                      size: 36,
                                      color: CafeColors.muted,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'La orden está vacía',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Toca un producto para agregarlo.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      itemCount: details.items.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (BuildContext context, int index) {
                        return _line(details.items[index]);
                      },
                    ),
            ),
            Container(
              color: CafeColors.espresso,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        formatPriceCents(details.order.totalCents),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: widget.controller.isSaving
                        ? null
                        : widget.onProceedToPayment,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Proceder al pago'),
                    iconAlignment: IconAlignment.end,
                    style: FilledButton.styleFrom(
                      backgroundColor: CafeColors.terracotta,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(OrderItem item) {
    final bool canIncrease = widget.controller.canIncrease(item);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.productNameSnapshot,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(formatPriceCents(item.totalCents)),
            ],
          ),
          Text(
            '${item.categoryNameSnapshot} · '
            '${formatPriceCents(item.unitPriceCents)} c/u',
          ),
          if (!canIncrease)
            const Text(
              'No disponible; solo puedes disminuir o eliminar.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          Row(
            children: <Widget>[
              IconButton.outlined(
                tooltip: item.quantity == 1 ? 'Eliminar producto' : 'Disminuir',
                onPressed: widget.controller.isSaving
                    ? null
                    : () => widget.controller.setQuantity(
                        item,
                        item.quantity - 1,
                      ),
                icon: Icon(
                  item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.outlined(
                tooltip: canIncrease ? 'Aumentar' : 'Producto no disponible',
                onPressed: widget.controller.isSaving || !canIncrease
                    ? null
                    : () => widget.controller.setQuantity(
                        item,
                        item.quantity + 1,
                      ),
                icon: const Icon(Icons.add),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Editar nota de ${item.productNameSnapshot}',
                onPressed: widget.controller.isSaving
                    ? null
                    : () => _editNote(item),
                icon: const Icon(Icons.edit_note),
              ),
            ],
          ),
          if (item.note != null) Text('Nota: ${item.note}'),
        ],
      ),
    );
  }

  Future<void> _editNote(OrderItem item) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => TextInputDialog(
        title: 'Nota · ${item.productNameSnapshot}',
        label: 'Nota de la línea',
        confirmLabel: 'Guardar nota',
        initialValue: item.note ?? '',
        hint: 'Ej. sin azúcar',
        minLines: 2,
        maxLines: 4,
      ),
    );
    if (result != null) {
      await widget.controller.saveNote(item, result);
    }
  }

  Future<void> _cancelOrder() async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const TextInputDialog(
        title: 'Cancelar orden',
        label: 'Motivo',
        confirmLabel: 'Cancelar orden',
        emptyMessage: 'Ingresa el motivo de cancelación.',
      ),
    );
    if (result == null) {
      return;
    }
    final bool cancelled = await widget.controller.cancel(result);
    if (cancelled && mounted) {
      widget.onCancelled();
    }
  }
}
