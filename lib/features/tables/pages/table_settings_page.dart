import 'package:flutter/material.dart';

import '../../../domain/entities/cafe_table.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../controllers/table_controller.dart';

class TableSettingsPage extends StatefulWidget {
  const TableSettingsPage({required this.controller, super.key});

  final TableController controller;

  @override
  State<TableSettingsPage> createState() => _TableSettingsPageState();
}

class _TableSettingsPageState extends State<TableSettingsPage> {
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
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text('Configuración · Mesas'),
            actions: <Widget>[
              if (widget.controller.isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
            ],
          ),
          floatingActionButton: widget.controller.status == TableStatus.ready
              ? FloatingActionButton.extended(
                  onPressed: widget.controller.isSaving
                      ? null
                      : () => _editTable(),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear mesa'),
                )
              : null,
          body: _body(),
        );
      },
    );
  }

  Widget _body() {
    switch (widget.controller.status) {
      case TableStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case TableStatus.error:
        return Center(
          child: FilledButton.icon(
            onPressed: widget.controller.load,
            icon: const Icon(Icons.refresh),
            label: Text(widget.controller.errorMessage!),
          ),
        );
      case TableStatus.ready:
        return _tableList();
    }
  }

  Widget _tableList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: <Widget>[
        const Text(
          'Las mesas inactivas no aparecen al crear órdenes. Una mesa ocupada '
          'no puede desactivarse.',
        ),
        if (widget.controller.errorMessage != null) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.controller.errorMessage!),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (widget.controller.tables.isEmpty)
          const Card.outlined(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aún no hay mesas. Crea la primera para recibir órdenes en el local.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...widget.controller.tables.indexed.map(((int, CafeTable) entry) {
            final int index = entry.$1;
            final CafeTable table = entry.$2;
            return Card(
              child: ListTile(
                enabled: !widget.controller.isSaving,
                leading: Icon(
                  table.isActive
                      ? Icons.table_restaurant
                      : Icons.visibility_off_outlined,
                ),
                title: Text(table.name),
                subtitle: Text(table.isActive ? 'Activa' : 'Inactiva'),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Acciones de ${table.name}',
                  enabled: !widget.controller.isSaving,
                  onSelected: (String action) =>
                      _tableAction(action, table, index),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Renombrar'),
                        ),
                        PopupMenuItem<String>(
                          value: 'up',
                          enabled: index > 0,
                          child: const Text('Mover arriba'),
                        ),
                        PopupMenuItem<String>(
                          value: 'down',
                          enabled: index < widget.controller.tables.length - 1,
                          child: const Text('Mover abajo'),
                        ),
                        PopupMenuItem<String>(
                          value: 'active',
                          child: Text(
                            table.isActive ? 'Desactivar' : 'Reactivar',
                          ),
                        ),
                      ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _tableAction(String action, CafeTable table, int index) async {
    switch (action) {
      case 'edit':
        await _editTable(table);
      case 'up':
        await widget.controller.moveTable(table, -1);
      case 'down':
        await widget.controller.moveTable(table, 1);
      case 'active':
        if (table.isActive && !await _confirmDeactivation(table)) {
          return;
        }
        await widget.controller.setTableActive(table, !table.isActive);
    }
  }

  Future<void> _editTable([CafeTable? table]) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => TextInputDialog(
        title: table == null ? 'Crear mesa' : 'Renombrar mesa',
        label: 'Nombre',
        confirmLabel: 'Guardar',
        initialValue: table?.name ?? '',
        emptyMessage: 'Ingresa un nombre.',
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    final bool saved = table == null
        ? await widget.controller.createTable(result)
        : await widget.controller.renameTable(table, result);
    if (saved && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mesa guardada.')));
    }
  }

  Future<bool> _confirmDeactivation(CafeTable table) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Desactivar ${table.name}'),
            content: const Text(
              'La mesa dejará de aparecer al crear órdenes. Si está ocupada, '
              'la operación será rechazada.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Desactivar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
