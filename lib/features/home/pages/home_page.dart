import 'package:flutter/material.dart';

import '../../../application/use_cases/order_use_cases.dart';
import '../../../domain/entities/cafe_table.dart';
import '../../../domain/entities/order.dart';
import '../../../shared/dates/cafe_dates.dart';
import '../../../shared/money/money_parser.dart';
import '../../../shared/presentation/cafe_colors.dart';
import '../../../shared/presentation/pos_page.dart';
import '../controllers/home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.controller,
    required this.onOpenOrder,
    this.creationOnly = false,
    super.key,
  });

  final HomeController controller;
  final ValueChanged<String> onOpenOrder;
  final bool creationOnly;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
          title: widget.creationOnly ? 'Nueva orden' : 'Inicio',
          subtitle: widget.creationOnly
              ? 'Elige una mesa libre o crea una orden para llevar'
              : 'Estado actual del salón y órdenes abiertas',
          isWorking: widget.controller.isSaving,
          actions: <Widget>[
            FilledButton.icon(
              onPressed: widget.controller.isSaving ? null : _createTakeaway,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Nueva para llevar'),
            ),
          ],
          body: _body(),
        );
      },
    );
  }

  Widget _body() {
    switch (widget.controller.status) {
      case HomeStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case HomeStatus.error:
        return _ErrorState(
          message: widget.controller.errorMessage!,
          retry: widget.controller.load,
        );
      case HomeStatus.ready:
        return _readyBody(widget.controller.data!);
    }
  }

  Widget _readyBody(HomeData data) {
    final List<CafeTable> visibleTables = widget.creationOnly
        ? data.tables
              .where((CafeTable table) => data.orderForTable(table.id) == null)
              .toList(growable: false)
        : data.tables;
    return RefreshIndicator(
      onRefresh: widget.controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: <Widget>[
          if (widget.controller.errorMessage != null) ...<Widget>[
            _ErrorBanner(message: widget.controller.errorMessage!),
            const SizedBox(height: 16),
          ],
          if (!widget.creationOnly) ...<Widget>[
            _summary(data),
            const SizedBox(height: 22),
          ],
          Text(
            widget.creationOnly ? 'Selecciona una mesa' : 'Mesas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            widget.creationOnly
                ? 'Solo se muestran mesas disponibles.'
                : 'Toca una mesa para abrir o continuar su orden.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: CafeColors.muted),
          ),
          const SizedBox(height: 14),
          if (visibleTables.isEmpty)
            const _EmptyState(
              title: 'No hay mesas disponibles',
              message: 'Crea o activa mesas desde Configuración.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 164,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: visibleTables.length,
              itemBuilder: (BuildContext context, int index) {
                final CafeTable table = visibleTables[index];
                final Order? order = data.orderForTable(table.id);
                return _TableCard(
                  table: table,
                  order: order,
                  enabled: !widget.controller.isSaving,
                  onPressed: () => order == null
                      ? _createDineIn(table.id)
                      : widget.onOpenOrder(order.id),
                );
              },
            ),
          if (!widget.creationOnly) ...<Widget>[
            const SizedBox(height: 30),
            Text(
              'Órdenes para llevar abiertas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (data.takeawayOrders.isEmpty)
              const _EmptyState(
                title: 'No hay órdenes para llevar',
                message: 'Las órdenes abiertas aparecerán aquí.',
              )
            else
              ...data.takeawayOrders.map((Order order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PosSurface(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      minTileHeight: 74,
                      leading: const CircleAvatar(
                        backgroundColor: CafeColors.amberSoft,
                        foregroundColor: CafeColors.amber,
                        child: Icon(Icons.shopping_bag_outlined),
                      ),
                      title: Text('Orden #${order.orderNumber}'),
                      subtitle: Text(_orderSubtitle(order)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => widget.onOpenOrder(order.id),
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _summary(HomeData data) {
    final int occupied = data.tables
        .where((CafeTable table) => data.orderForTable(table.id) != null)
        .length;
    final List<Widget> metrics = <Widget>[
      PosMetricCard(
        label: 'Mesas libres',
        value: '${data.tables.length - occupied}',
        icon: Icons.table_restaurant_outlined,
        foreground: CafeColors.sage,
        background: CafeColors.sageSoft,
      ),
      PosMetricCard(
        label: 'Mesas ocupadas',
        value: '$occupied',
        icon: Icons.receipt_long_outlined,
        foreground: CafeColors.terracotta,
        background: CafeColors.terracottaSoft,
      ),
      PosMetricCard(
        label: 'Para llevar',
        value: '${data.takeawayOrders.length}',
        icon: Icons.shopping_bag_outlined,
        foreground: CafeColors.amber,
        background: CafeColors.amberSoft,
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: <Widget>[
              for (int index = 0; index < metrics.length; index++) ...<Widget>[
                metrics[index],
                if (index < metrics.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }
        return Row(
          children: <Widget>[
            for (int index = 0; index < metrics.length; index++) ...<Widget>[
              Expanded(child: metrics[index]),
              if (index < metrics.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Future<void> _createDineIn(String tableId) async {
    final Order? order = await widget.controller.createDineIn(tableId);
    if (order != null && mounted) {
      widget.onOpenOrder(order.id);
    }
  }

  Future<void> _createTakeaway() async {
    final Order? order = await widget.controller.createTakeaway();
    if (order != null && mounted) {
      widget.onOpenOrder(order.id);
    }
  }

  String _orderSubtitle(Order order) {
    return '${formatCafeTime(order.createdAt)} · '
        '${formatPriceCents(order.totalCents)} · '
        '${formatOpenDuration(order.createdAt, DateTime.now())}';
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.table,
    required this.order,
    required this.enabled,
    required this.onPressed,
  });

  final CafeTable table;
  final Order? order;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool occupied = order != null;
    final Color accent = occupied ? CafeColors.terracotta : CafeColors.sage;
    final Color soft = occupied
        ? CafeColors.terracottaSoft
        : CafeColors.sageSoft;
    return Semantics(
      button: true,
      excludeSemantics: true,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      label: '${table.name}, ${occupied ? 'ocupada' : 'libre'}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: occupied ? accent : CafeColors.outlineSoft),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        occupied
                            ? Icons.receipt_long_rounded
                            : Icons.table_restaurant_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        table.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                PosStatusPill(
                  label: occupied ? 'Ocupada' : 'Libre',
                  icon: occupied ? Icons.schedule : Icons.check_circle_outline,
                  foreground: accent,
                  background: soft,
                ),
                if (order case final Order value)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      'Orden #${value.orderNumber} · '
                      '${formatPriceCents(value.totalCents)}',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.error_outline),
      actions: const <Widget>[SizedBox.shrink()],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});

  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(Icons.table_restaurant_outlined, size: 40),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
