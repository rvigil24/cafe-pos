import 'package:flutter/material.dart';

import '../../../domain/entities/backup_result.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../../tables/controllers/table_controller.dart';
import '../../tables/pages/table_settings_page.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.controller,
    required this.tableController,
    super.key,
  });

  final SettingsController controller;
  final TableController tableController;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: TableSettingsPage(controller: widget.tableController)),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 380,
          child: ScaffoldMessenger(
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (BuildContext context, Widget? child) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Negocio y respaldos'),
                    actions: <Widget>[
                      if (widget.controller.isWorking)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                    ],
                  ),
                  body: _body(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    switch (widget.controller.status) {
      case SettingsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SettingsStatus.error:
        return Center(
          child: FilledButton.icon(
            onPressed: widget.controller.load,
            icon: const Icon(Icons.refresh),
            label: Text(widget.controller.errorMessage!),
          ),
        );
      case SettingsStatus.ready:
        return _settings();
    }
  }

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Negocio', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card.outlined(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(Icons.store_outlined),
            title: Text(widget.controller.settings!.businessName),
            subtitle: const Text('Nombre mostrado para este negocio'),
            trailing: IconButton(
              tooltip: 'Editar nombre del negocio',
              onPressed: widget.controller.isWorking ? null : _editBusinessName,
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Respaldos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Guarda una copia fuera de la aplicación para recuperar catálogo, '
          'mesas, órdenes, pagos y configuración.',
        ),
        if (widget.controller.errorMessage != null) ...<Widget>[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.controller.errorMessage!),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.controller.isWorking ? null : _exportBackup,
          icon: const Icon(Icons.save_alt),
          label: const Text('Exportar respaldo'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.controller.isWorking ? null : _confirmRestore,
          icon: const Icon(Icons.settings_backup_restore),
          label: const Text('Restaurar respaldo'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Antes de restaurar, Cafe POS valida el archivo y conserva una copia '
          'preventiva de los datos actuales.',
        ),
      ],
    );
  }

  Future<void> _editBusinessName() async {
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => TextInputDialog(
        title: 'Nombre del negocio',
        label: 'Nombre',
        confirmLabel: 'Guardar',
        initialValue: widget.controller.settings!.businessName,
        emptyMessage: 'Ingresa el nombre del negocio.',
      ),
    );
    if (value == null || !mounted) {
      return;
    }
    if (await widget.controller.saveBusinessName(value) && mounted) {
      _show('Nombre del negocio guardado.');
    }
  }

  Future<void> _exportBackup() async {
    final BackupExportResult? result = await widget.controller.exportBackup();
    if (result != null && mounted) {
      _show('Respaldo ${result.fileName} exportado.');
    }
  }

  Future<void> _confirmRestore() async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Restaurar un respaldo'),
            content: const Text(
              'Los datos actuales serán reemplazados por el respaldo elegido. '
              'Antes del cambio se creará una copia preventiva.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Elegir respaldo'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    final BackupRestoreResult? result = await widget.controller.restoreBackup();
    if (result != null && mounted) {
      await widget.tableController.load();
      if (mounted) {
        _show('Respaldo ${result.sourceName} restaurado.');
      }
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
