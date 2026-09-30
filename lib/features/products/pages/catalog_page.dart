import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/errors/domain_error.dart';
import '../../../shared/money/money_parser.dart';
import '../controllers/catalog_controller.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({required this.controller, super.key});

  final CatalogController controller;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
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
            title: const Text('Productos'),
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
          body: _body(),
        );
      },
    );
  }

  Widget _body() {
    switch (widget.controller.status) {
      case CatalogStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CatalogStatus.error:
        return _ErrorState(
          message: widget.controller.errorMessage!,
          retry: widget.controller.load,
        );
      case CatalogStatus.ready:
        return _readyBody();
    }
  }

  Widget _readyBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          width: 300,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Categorías',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Crear categoría',
                        onPressed: widget.controller.isSaving
                            ? null
                            : _createCategory,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _categoryList()),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _productArea()),
      ],
    );
  }

  Widget _categoryList() {
    if (widget.controller.categories.isEmpty) {
      return const _EmptyState(
        icon: Icons.category_outlined,
        title: 'Aún no hay categorías',
        message: 'Crea una categoría para comenzar el catálogo.',
      );
    }
    return ListView.builder(
      itemCount: widget.controller.categories.length,
      itemBuilder: (BuildContext context, int index) {
        final Category category = widget.controller.categories[index];
        return ListTile(
          selected: category.id == widget.controller.selectedCategoryId,
          enabled: !widget.controller.isSaving,
          onTap: () => widget.controller.selectCategory(category.id),
          title: Text(category.name),
          subtitle: category.isActive ? null : const Text('Inactiva'),
          trailing: PopupMenuButton<String>(
            tooltip: 'Acciones de ${category.name}',
            enabled: !widget.controller.isSaving,
            onSelected: (String action) =>
                _categoryAction(action, category, index),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
              PopupMenuItem<String>(
                value: 'up',
                enabled: index > 0,
                child: const Text('Mover arriba'),
              ),
              PopupMenuItem<String>(
                value: 'down',
                enabled: index < widget.controller.categories.length - 1,
                child: const Text('Mover abajo'),
              ),
              PopupMenuItem<String>(
                value: 'active',
                child: Text(category.isActive ? 'Desactivar' : 'Reactivar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _productArea() {
    final Category? category = widget.controller.selectedCategory;
    if (category == null) {
      return const _EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Catálogo vacío',
        message: 'Crea una categoría y luego agrega productos.',
      );
    }
    final List<Product> products = widget.controller.selectedProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (!category.isActive)
                      const Text(
                        'Esta categoría y sus productos están ocultos en ventas.',
                      ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: widget.controller.isSaving
                    ? null
                    : () => _editProduct(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo producto'),
              ),
            ],
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const _EmptyState(
                  icon: Icons.local_cafe_outlined,
                  title: 'No hay productos',
                  message: 'Agrega el primer producto de esta categoría.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    return _productCard(products[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _productCard(Product product) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(product.name),
        subtitle: Text(
          '${formatPriceCents(product.priceCents)} · '
          '${product.isActive ? (product.isAvailable ? 'Disponible' : 'Agotado') : 'Inactivo'}',
        ),
        leading: Icon(
          product.isAvailable && product.isActive
              ? Icons.check_circle_outline
              : Icons.remove_circle_outline,
        ),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (product.isActive)
              FilterChip(
                label: Text(product.isAvailable ? 'Disponible' : 'Agotado'),
                selected: product.isAvailable,
                onSelected: widget.controller.isSaving
                    ? null
                    : (bool value) => _run(
                        widget.controller.setProductAvailable(product, value),
                        'Disponibilidad actualizada.',
                      ),
              ),
            IconButton(
              tooltip: 'Editar ${product.name}',
              onPressed: widget.controller.isSaving
                  ? null
                  : () => _editProduct(product),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: product.isActive
                  ? 'Desactivar ${product.name}'
                  : 'Reactivar ${product.name}',
              onPressed: widget.controller.isSaving
                  ? null
                  : () => _toggleProduct(product),
              icon: Icon(
                product.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCategory() async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _CategoryDialog(),
    );
    if (name != null) {
      await _run(widget.controller.createCategory(name), 'Categoría creada.');
    }
  }

  Future<void> _categoryAction(
    String action,
    Category category,
    int index,
  ) async {
    if (action == 'edit') {
      final String? name = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => _CategoryDialog(category: category),
      );
      if (name != null) {
        await _run(
          widget.controller.renameCategory(category, name),
          'Categoría actualizada.',
        );
      }
    } else if (action == 'up') {
      await _run(
        widget.controller.moveCategory(category, -1),
        'Orden guardado.',
      );
    } else if (action == 'down') {
      await _run(
        widget.controller.moveCategory(category, 1),
        'Orden guardado.',
      );
    } else if (action == 'active') {
      if (category.isActive && !await _confirmDeactivate(category.name)) {
        return;
      }
      await _run(
        widget.controller.setCategoryActive(category, !category.isActive),
        category.isActive ? 'Categoría desactivada.' : 'Categoría reactivada.',
      );
    }
  }

  Future<void> _editProduct([Product? product]) async {
    final _ProductInput? input = await showDialog<_ProductInput>(
      context: context,
      builder: (BuildContext context) => _ProductDialog(
        categories: widget.controller.categories,
        initialCategoryId:
            product?.categoryId ?? widget.controller.selectedCategoryId!,
        product: product,
      ),
    );
    if (input == null) {
      return;
    }
    final Future<bool> result = product == null
        ? widget.controller.createProduct(
            categoryId: input.categoryId,
            name: input.name,
            price: input.price,
          )
        : widget.controller.editProduct(
            product: product,
            categoryId: input.categoryId,
            name: input.name,
            price: input.price,
          );
    await _run(
      result,
      product == null ? 'Producto creado.' : 'Producto guardado.',
    );
  }

  Future<void> _toggleProduct(Product product) async {
    if (product.isActive && !await _confirmDeactivate(product.name)) {
      return;
    }
    await _run(
      widget.controller.setProductActive(product, !product.isActive),
      product.isActive ? 'Producto desactivado.' : 'Producto reactivado.',
    );
  }

  Future<bool> _confirmDeactivate(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Confirmar desactivación'),
            content: Text(
              '$name dejará de aparecer al crear órdenes. El historial no cambiará.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
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

  Future<void> _run(Future<bool> operation, String success) async {
    final bool succeeded = await operation;
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(succeeded ? success : widget.controller.errorMessage!),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final Category? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.category?.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AlertDialog(
      scrollable: keyboardVisible,
      title: keyboardVisible
          ? null
          : Text(
              widget.category == null ? 'Nueva categoría' : 'Editar categoría',
            ),
      contentPadding: keyboardVisible
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 8)
          : null,
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: (String? value) => value == null || value.trim().isEmpty
              ? 'Ingresa un nombre.'
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: keyboardVisible
          ? const <Widget>[]
          : <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(onPressed: _submit, child: const Text('Guardar')),
            ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _name.text);
    }
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({
    required this.categories,
    required this.initialCategoryId,
    this.product,
  });

  final List<Category> categories;
  final String initialCategoryId;
  final Product? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _categoryId = widget.initialCategoryId;
  late final TextEditingController _name = TextEditingController(
    text: widget.product?.name,
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.product == null
        ? ''
        : formatPriceCents(widget.product!.priceCents),
  );

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AlertDialog(
      scrollable: keyboardVisible,
      title: keyboardVisible
          ? null
          : Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
      contentPadding: keyboardVisible
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 8)
          : null,
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: widget.categories
                    .map(
                      (Category category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) => _categoryId = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Ingresa un nombre.'
                    : null,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  hintText: '2.50',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                validator: (String? value) {
                  try {
                    parsePriceCents(value ?? '');
                    return null;
                  } on ValidationError catch (error) {
                    return error.message;
                  }
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: keyboardVisible
          ? const <Widget>[]
          : <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(onPressed: _submit, child: const Text('Guardar')),
            ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        _ProductInput(
          categoryId: _categoryId,
          name: _name.text,
          price: _price.text,
        ),
      );
    }
  }
}

class _ProductInput {
  const _ProductInput({
    required this.categoryId,
    required this.name,
    required this.price,
  });

  final String categoryId;
  final String name;
  final String price;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
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
          const Icon(Icons.error_outline, size: 56),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
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
