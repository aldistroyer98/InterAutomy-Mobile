import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/catalog_readiness.dart';
import '../../../domain/entities/comodato.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/services/comodato_resolution_service.dart';
import '../../../state/app_controller.dart';
import '../../../state/app_state.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  String? _lineFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final state = ref.read(appControllerProvider);
    if (state.selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un cliente antes de agregar productos.'),
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<_AddProductResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AddProductSheet(appState: state),
    );
    if (result == null) return;
    ref
        .read(appControllerProvider.notifier)
        .addCatalogProduct(
          result.product,
          quantity: result.quantity,
          explicitComodato: result.comodato,
          forceNoComodato: result.sinComodato,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto agregado al envío.')),
    );
  }

  Future<void> _editProduct(SelectedProduct product) async {
    final state = ref.read(appControllerProvider);
    final result = await showModalBottomSheet<SelectedProduct>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _EditProductSheet(product: product, appState: state),
    );
    if (result != null) {
      ref.read(appControllerProvider.notifier).updateProduct(result);
    }
  }

  Future<void> _removeProduct(SelectedProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Deseas eliminar ${product.nombre} del envío?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(appControllerProvider.notifier).removeProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final query = _searchController.text.trim().toLowerCase();
    final products = state.selectedProducts
        .where((product) {
          final matchesLine =
              _lineFilter == null || product.linea.id == _lineFilter;
          final matchesSearch =
              query.isEmpty ||
              product.codigo.toLowerCase().contains(query) ||
              product.nombre.toLowerCase().contains(query);
          return matchesLine && matchesSearch;
        })
        .toList(growable: false);
    final currency = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

    return CustomScrollView(
      key: const PageStorageKey('products-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              TextField(
                key: const Key('product-search'),
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar productos seleccionados',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _lineFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por línea',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas las líneas'),
                  ),
                  ...state.lines.map(
                    (line) => DropdownMenuItem(
                      value: line.id,
                      child: Text(line.nombre),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _lineFilter = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${state.selectedProducts.length} producto(s) · ${state.selectedProducts.any((item) => !item.hasVerifiedPrice) ? 'Total pendiente de precios' : currency.format(state.total)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('add-product'),
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyProducts(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 900 ? 2 : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 318,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductCard(
                      product: products[index],
                      currency: currency,
                      onEdit: () => _editProduct(products[index]),
                      onDuplicate: () => ref
                          .read(appControllerProvider.notifier)
                          .duplicateProduct(products[index].id),
                      onRemove: () => _removeProduct(products[index]),
                      onDecrease: () => ref
                          .read(appControllerProvider.notifier)
                          .changeQuantity(products[index].id, -1),
                      onIncrease: () => ref
                          .read(appControllerProvider.notifier)
                          .changeQuantity(products[index].id, 1),
                    ),
                    childCount: products.length,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay productos para mostrar.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Agrega un producto o cambia los filtros.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.currency,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRemove,
    required this.onDecrease,
    required this.onIncrease,
  });

  final SelectedProduct product;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.nombre,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acciones del producto',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'duplicate') onDuplicate();
                    if (value == 'delete') onRemove();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            Text(
              product.hasVerifiedCode
                  ? product.codigo
                  : 'Código no disponible en el maestro IA1',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            _ReadinessChip(readiness: product.readiness),
            const SizedBox(height: 8),
            Text(
              product.linea.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product.hasVerifiedPresentation
                  ? product.presentacion
                  : 'Presentación pendiente de fuente autorizada',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Comodato: ${product.sinComodato ? 'Sin comodato' : product.comodato?.codigo ?? 'No resuelto'}',
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  product.hasVerifiedPrice
                      ? currency.format(product.precio)
                      : 'Precio pendiente',
                ),
                const Spacer(),
                IconButton(
                  onPressed: onDecrease,
                  tooltip: 'Disminuir cantidad',
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${product.cantidad}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: onIncrease,
                  tooltip: 'Aumentar cantidad',
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                product.hasVerifiedPrice
                    ? 'Subtotal: ${currency.format(product.subtotal)}'
                    : 'Subtotal pendiente de precio',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AddProductResult {
  const _AddProductResult(
    this.product,
    this.quantity,
    this.comodato, {
    this.sinComodato = false,
  });

  final CatalogProduct product;
  final int quantity;
  final Comodato? comodato;
  final bool sinComodato;
}

class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet({required this.appState});

  final AppState appState;

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  String? _lineId;
  String? _productId;
  String? _comodatoId;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  List<CatalogProduct> get _products => widget.appState.catalog
      .where((product) => _lineId == null || product.linea.id == _lineId)
      .toList(growable: false);

  CatalogProduct? get _product {
    final matches = _products.where((product) => product.id == _productId);
    return matches.isEmpty ? null : matches.first;
  }

  List<Comodato> get _comodatos {
    final client = widget.appState.selectedClient;
    if (client == null || _lineId == null) return const [];
    final values = [
      ...?client.comodatosPorLinea[_lineId],
      ...?client.comodatosPorLinea['general'],
    ];
    final unique = <String, Comodato>{
      for (final value in values) value.id: value,
    };
    return unique.values.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Agregar producto',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('add-product-line'),
                initialValue: _lineId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '1. Línea'),
                items: widget.appState.lines
                    .map(
                      (line) => DropdownMenuItem(
                        value: line.id,
                        child: Text(line.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _lineId = value;
                  _productId = null;
                  _comodatoId = null;
                }),
                validator: (value) =>
                    value == null ? 'Selecciona una línea.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('product-$_lineId'),
                initialValue: _productId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '2. Producto'),
                items: _products
                    .map(
                      (product) => DropdownMenuItem(
                        value: product.id,
                        child: Text(
                          product.hasVerifiedCode
                              ? '${product.codigo} · ${product.nombre}'
                              : '${product.nombre} · ${product.readiness.statusLabel}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _lineId == null
                    ? null
                    : (value) => setState(() {
                        _productId = value;
                        _comodatoId = null;
                      }),
                validator: (value) =>
                    value == null ? 'Selecciona un producto.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey('comodato-$_lineId-$_productId'),
                initialValue: _comodatoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '3. Comodato'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Resolver automáticamente'),
                  ),
                  const DropdownMenuItem(
                    value: '__none__',
                    child: Text('Sin comodato'),
                  ),
                  ..._comodatos.map(
                    (comodato) => DropdownMenuItem(
                      value: comodato.id,
                      child: Text(comodato.etiqueta),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _comodatoId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('add-product-quantity'),
                controller: _quantityController,
                decoration: const InputDecoration(labelText: '4. Cantidad'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  return parsed == null || parsed <= 0
                      ? 'Ingresa una cantidad válida.'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('confirm-add-product'),
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  final product = _product!;
                  final comodatoMatches = _comodatos.where(
                    (item) => item.id == _comodatoId,
                  );
                  Navigator.pop(
                    context,
                    _AddProductResult(
                      product,
                      int.parse(_quantityController.text),
                      comodatoMatches.isEmpty ? null : comodatoMatches.first,
                      sinComodato: _comodatoId == '__none__',
                    ),
                  );
                },
                child: const Text('Confirmar producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({required this.readiness});

  final CatalogReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (readiness) {
      CatalogReadiness.complete => (
        Icons.check_circle_outline,
        colorScheme.primary,
      ),
      CatalogReadiness.notExecutable => (
        Icons.block_outlined,
        colorScheme.error,
      ),
      _ => (Icons.warning_amber_outlined, colorScheme.tertiary),
    };
    return Tooltip(
      message: readiness.reasonLabel,
      child: Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(icon, size: 18, color: color),
        label: Text(readiness.statusLabel),
      ),
    );
  }
}

class _EditProductSheet extends StatefulWidget {
  const _EditProductSheet({required this.product, required this.appState});

  final SelectedProduct product;
  final AppState appState;

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  late String _comodatoId;

  List<Comodato> get _comodatos {
    final client = widget.appState.selectedClient;
    if (client == null) return const [];
    return [
      ...?client.comodatosPorLinea[widget.product.linea.id],
      ...?client.comodatosPorLinea['general'],
    ];
  }

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
      text: widget.product.precio.toStringAsFixed(2),
    );
    _quantity = TextEditingController(text: '${widget.product.cantidad}');
    _comodatoId = widget.product.sinComodato
        ? '__none__'
        : widget.product.comodato?.id ?? '__auto__';
  }

  @override
  void dispose() {
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Editar producto',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(widget.product.nombre),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Precio unitario'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  return parsed == null || parsed <= 0
                      ? 'Ingresa un precio válido.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  return parsed == null || parsed <= 0
                      ? 'Ingresa una cantidad válida.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _comodatoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Comodato'),
                items: [
                  const DropdownMenuItem(
                    value: '__auto__',
                    child: Text('Resolver automáticamente'),
                  ),
                  const DropdownMenuItem(
                    value: '__none__',
                    child: Text('Ninguno'),
                  ),
                  ..._comodatos.map(
                    (comodato) => DropdownMenuItem(
                      value: comodato.id,
                      child: Text(comodato.etiqueta),
                    ),
                  ),
                ],
                onChanged: (value) => _comodatoId = value ?? '__none__',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  final matches = _comodatos.where(
                    (item) => item.id == _comodatoId,
                  );
                  final forceNone = _comodatoId == '__none__';
                  final explicit = matches.isEmpty ? null : matches.first;
                  final client = widget.appState.selectedClient;
                  final resolution = client == null
                      ? ComodatoResolution(
                          source: forceNone
                              ? ComodatoResolutionSource.none
                              : explicit == null
                              ? ComodatoResolutionSource.none
                              : ComodatoResolutionSource.explicit,
                          comodato: forceNone ? null : explicit,
                        )
                      : ComodatoResolutionService.resolve(
                          client: client,
                          lineId: widget.product.linea.id,
                          explicit: explicit,
                          forceNone: forceNone,
                        );
                  Navigator.pop(
                    context,
                    widget.product.copyWith(
                      precio: double.parse(_price.text.replaceAll(',', '.')),
                      cantidad: int.parse(_quantity.text),
                      comodato: resolution.comodato,
                      clearComodato: resolution.comodato == null,
                      sinComodato: forceNone,
                      comodatoValid: resolution.valid,
                    ),
                  );
                },
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
